# frozen_string_literal: true

class Views::Users::Edit < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  def initialize(user:)
    @user = user
  end

  def view_template
    content_for :title, t("users.edit.title")

    div(class: "max-w-2xl mx-auto py-12 px-4 sm:px-6") do
      div(class: "mb-2 px-1") do
        render RubyUI::Heading.new(level: 1, class: "text-3xl font-bold text-content tracking-tight") { t("users.edit.heading") }
        p(class: "mt-1 text-content-muted") { t("users.edit.subtitle") }
      end

      render Components::Users::Form.new(user: @user)

      div(class: "mt-6 px-1") do
        link_to t("users.edit.blog_link"), account_blog_path,
          class: "text-sm font-medium text-accent-text hover:underline"
      end
    end
  end
end
