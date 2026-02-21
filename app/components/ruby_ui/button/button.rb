# frozen_string_literal: true

module RubyUI
  class Button < Base
    BASE_CLASSES = [
      "whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors",
      "disabled:pointer-events-none disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
      "aria-disabled:pointer-events-none aria-disabled:opacity-50 aria-disabled:cursor-not-allowed"
    ].freeze

    def initialize(type: :button, variant: :primary, size: :md, icon: false, **attrs)
      @type = type
      @variant = variant.to_sym
      @size = size.to_sym
      @icon = icon
      super(**attrs)
    end

    def view_template(&)
      button(**attrs, &)
    end

    private

    def size_classes
      if @icon
        { sm: "h-6 w-6", md: "h-9 w-9", lg: "h-10 w-10", xl: "h-12 w-12" }[@size]
      else
        { sm: "px-3 py-1.5 h-8 text-xs", md: "px-4 py-2 h-9 text-sm", lg: "px-4 py-2 h-10 text-base", xl: "px-6 py-3 h-12 text-base" }[@size]
      end
    end

    def primary_classes
      [
        BASE_CLASSES,
        size_classes,
        "bg-primary text-primary-foreground shadow",
        "hover:bg-primary/90"
      ]
    end

    def link_classes
      [
        BASE_CLASSES,
        size_classes,
        "text-primary underline-offset-4",
        "hover:underline"
      ]
    end

    def secondary_classes
      [
        BASE_CLASSES,
        size_classes,
        "bg-secondary text-secondary-foreground",
        "hover:bg-opacity-80"
      ]
    end

    def destructive_classes
      [
        BASE_CLASSES,
        size_classes,
        "bg-destructive text-destructive-foreground shadow-sm",
        "[a&]:hover:bg-destructive/90 focus-visible:ring-destructive/20",
        "dark:focus-visible:ring-destructive/40 dark:bg-destructive/60"
      ]
    end

    def success_classes
      [
        BASE_CLASSES,
        size_classes,
        "bg-green-500 text-white shadow",
        "hover:bg-green-600 focus-visible:ring-green-500/20"
      ]
    end

    def outline_classes
      [
        BASE_CLASSES,
        size_classes,
        "border border-input bg-background shadow-sm",
        "hover:bg-accent hover:text-accent-foreground"
      ]
    end

    def ghost_classes
      [
        BASE_CLASSES,
        size_classes,
        "hover:bg-accent hover:text-accent-foreground"
      ]
    end

    def default_classes
      case @variant
      when :primary then primary_classes
      when :link then link_classes
      when :secondary then secondary_classes
      when :destructive then destructive_classes
      when :success then success_classes
      when :outline then outline_classes
      when :ghost then ghost_classes
      end
    end

    def default_attrs
      { type: @type, class: default_classes }
    end
  end
end
