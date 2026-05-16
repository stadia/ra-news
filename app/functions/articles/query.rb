# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module Query
    DEFAULT_INCLUDES = %i[user site tags thumbnail_attachment].freeze

    module_function

    def index_html(search = nil)
      index_scope(search).where.not(id: excluded_related_article_ids(base_scope.related))
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

    def index_scope(search)
      if search.present?
        base_scope.full_text_search_for(search).includes(*DEFAULT_INCLUDES).without_toast
      else
        base_scope.related.includes(*DEFAULT_INCLUDES).without_toast
      end
    end

    def excluded_related_article_ids(scope)
      recent_scope = scope.where(created_at: 24.hours.ago...).order(created_at: :desc)
      target_scope = if recent_scope.count < 9
        scope.order(created_at: :desc).limit(9)
      else
        recent_scope
      end
      target_scope.pluck(:id)
    end

    def others_scope
      base_scope.includes(*DEFAULT_INCLUDES).without_toast
    end

    def base_scope
      Article.kept.confirmed
    end

    private_class_method :base_scope, :index_scope, :others_scope, :excluded_related_article_ids
  end
end
