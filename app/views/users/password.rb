# typed: true
# frozen_string_literal: true

class Views::Users::Password < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include PhlexIcons

  def initialize(user:)
    @user = user
  end

  def view_template
    content_for :title, t("users.password.title")

    div(class: "max-w-2xl mx-auto py-12 px-4 sm:px-6") do
      div(class: "mb-2 px-1") do
        render RubyUI::Heading.new(level: 1, class: "text-3xl font-bold text-content tracking-tight") { t("users.password.heading") }
        p(class: "mt-1 text-content-muted") { t("users.password.subtitle") }
      end

      render Components::Users::PwdForm.new(user: @user)
    end
  end
end
