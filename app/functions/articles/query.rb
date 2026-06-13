# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module Query
    extend FunctionLogger

    DEFAULT_INCLUDES = %i[user site tags thumbnail_attachment].freeze

    class << self
      def index_html(search = nil)
        return html_candidate_scope(search) if search.present?

        related_scope.where.not(id: excluded_related_article_ids(base_scope.related))
                     .order(published_at: :desc)
      end

      def index_json(search = nil)
        return json_candidate_scope(search) if search.present?

        related_scope.order(published_at: :desc, id: :desc)
      end

      def others
        others_scope.unrelated.order(published_at: :desc, id: :desc)
      end

      def tagged(keyword)
        others_scope.tagged_with(keyword, on: :tags).order(published_at: :desc, id: :desc)
      end

      private

      def related_scope
        base_scope.related.includes(*DEFAULT_INCLUDES).without_toast
      end

      JSON_SEARCH_LIMIT = 50
      PAGE_FACTOR = 5

      # API(JSON) 검색: 하이브리드로 관련 기사 후보 id 집합만 구한다.
      # 정렬은 호출부(api/v1/articles#index)의 reorder(published_at desc)가 담당하므로
      # in_order_of로 관련도 순위를 매기지 않는다 — keyset 페이지네이션 호환을 유지한다.
      def json_candidate_scope(search)
        ids = Articles::HybridSearch.run(query: search, limit: JSON_SEARCH_LIMIT)
        return base_scope.none if ids.empty?

        base_scope.where(id: ids).includes(*DEFAULT_INCLUDES).without_toast
                .order(published_at: :desc, id: :desc)
      end

      def html_candidate_scope(search)
        page_size = Pagy::DEFAULT[:items] || 10
        ids = Articles::HybridSearch.run(query: search, limit: page_size * PAGE_FACTOR)
        return base_scope.none if ids.empty?

        base_scope.where(id: ids).in_order_of(:id, ids)
                  .includes(*DEFAULT_INCLUDES).without_toast
      end

      def excluded_related_article_ids(scope)
        recent_ids = scope.where(created_at: 24.hours.ago...).order(created_at: :desc).pluck(:id)
        return recent_ids if recent_ids.size >= 9

        scope.order(created_at: :desc).limit(9).pluck(:id)
      end

      def others_scope
        base_scope.includes(*DEFAULT_INCLUDES).without_toast
      end

      def base_scope
        Article.kept.confirmed
      end
    end
  end
end
