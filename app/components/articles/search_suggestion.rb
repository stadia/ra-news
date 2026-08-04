# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Components
  module Articles
    class SearchSuggestion < Components::Base
      #: (query: String) -> void
      def initialize(query:)
        @query = query
      end

      def view_template
        a(
          href: helpers.articles_path(search: @query),
          class: "inline-block px-3 py-1 mx-1 my-1 rounded-full bg-surface-secondary
                  text-sm text-content hover:bg-surface-hover transition-colors"
        ) { @query }
      end
    end
  end
end
