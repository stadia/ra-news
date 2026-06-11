# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module Query
    extend FunctionLogger

    DEFAULT_INCLUDES = %i[user site tags thumbnail_attachment].freeze

    class << self
      def index_html(search = nil)
        return hybrid_search_scope(search) if search.present?

        index_scope(nil).where.not(id: excluded_related_article_ids(base_scope.related))
                        .order(published_at: :desc)
      end

      def index_json(search = nil)
        index_scope(search)
      end

      def others
        others_scope.unrelated
      end

      def tagged(keyword)
        others_scope.tagged_with(keyword, on: :tags)
      end

      private

      def index_scope(search)
        if search.present?
          base_scope.full_text_search_for(search).includes(*DEFAULT_INCLUDES).without_toast
        else
          base_scope.related.includes(*DEFAULT_INCLUDES).without_toast
        end
      end

      PAGE_FACTOR = 5

      def hybrid_search_scope(search)
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
