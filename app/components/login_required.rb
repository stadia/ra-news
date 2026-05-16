# frozen_string_literal: true

class Components::LoginRequired < Components::Base
  include PhlexIcons

  def initialize(title: nil, message: nil)
    @title = title
    @message = message
  end

  def view_template
    render RubyUI::Card.new(class: "bg-surface-muted border-border-muted p-8 text-center") do
      div(class: "inline-flex items-center justify-center w-12 h-12 rounded-full bg-surface mb-4") do
        Hero::LockClosed(variant: :outline, class: "w-6 h-6 text-content-secondary")
      end

      h3(class: "text-lg font-medium text-content mb-2") { @title || t("login_required.title") }
      p(class: "text-content-muted mb-6") { @message || t("login_required.message") }

      render RubyUI::Link.new(
        href: new_user_session_path,
        class: "inline-flex items-center px-5 py-2.5 bg-info-solid hover:bg-info-solid-hover text-brand-foreground font-medium rounded-lg transition-colors duration-200",
        data: { turbo: false }
      ) do
        plain t("login_required.go_to_login")
        Hero::ArrowRight(variant: :outline, class: "w-4 h-4 ml-2")
      end
    end
  end
end
