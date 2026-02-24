# frozen_string_literal: true

module RubyUI
  class PaginationItem < Base
    def initialize(href: "#", active: false, **attrs)
      @href = href
      @active = active
      super(**attrs)
    end

    def view_template(&block)
      li do
        a(href: @href, **attrs, &block)
      end
    end

    private

    def default_attrs
      {
        aria: { current: @active ? "page" : nil },
        class: [
          RubyUI::Button.new(variant: @active ? :outline : :ghost).attrs[:class],
          (@active ? "bg-green-500 text-white hover:bg-green-600 border border-green-400/60 ring-1 ring-green-400/40" : nil)
        ]
      }
    end
  end
end
