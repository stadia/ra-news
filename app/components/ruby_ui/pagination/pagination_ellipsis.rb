# frozen_string_literal: true

module RubyUI
  class PaginationEllipsis < Base
    include PhlexIcons

    def view_template(&block)
      li do
        span(**attrs) do
          icon
          span(class: "sr-only") { "More pages" }
        end
      end
    end

    private

    def icon
      Hero::EllipsisHorizontal(variant: :outline, class: "h-4 w-4")
    end

    def default_attrs
      {
        aria: { hidden: true },
        class: "flex h-9 w-9 items-center justify-center"
      }
    end
  end
end
