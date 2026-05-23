# frozen_string_literal: true

class Components::OauthButton::Github < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(path:, label:)
    @path = path
    @label = label
  end

  def view_template
    form_with(url: @path, method: :post, data: { turbo: false }, class: "w-full sm:w-auto") do
      button(
        type: "submit",
        class: [
          "inline-flex h-10 w-full items-center justify-center gap-3",
          "rounded-md border border-border-muted bg-surface px-3",
          "text-sm font-medium leading-none text-content",
          "cursor-pointer hover:bg-surface-hover active:bg-surface-muted",
          "focus:outline-none focus:ring-2 focus:ring-brand focus:ring-offset-2 focus:ring-offset-app"
        ].join(" ")
      ) do
        render PhlexIcons::Hero::CodeBracketSquare.new(variant: :outline, class: "size-5")
        span { @label }
      end
    end
  end
end
