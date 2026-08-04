# typed: true
# frozen_string_literal: true

class Views::Users::OauthSignup < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(user:, email:, name:)
    @user = user
    @email = email
    @name = name
  end

  def view_template
    div(class: "max-w-2xl mx-auto py-12 px-4 sm:px-6") do
      div(class: "mb-6") do
        render RubyUI::Heading.new(level: 1, class: "text-3xl font-bold") { t("users.oauth_signup.heading") }
        p(class: "mt-2 text-content-muted") { t("users.oauth_signup.subtitle") }
      end

      form_with(url: user_oauth_registration_path, scope: :user, class: "space-y-5") do |form|
        if @user.errors.any?
          div(id: "error_explanation", class: "rounded-xl border border-danger-solid/20 bg-danger-solid/10 p-4 text-danger-text") do
            h2(class: "mb-2 font-bold") { t("errors.messages.form_errors", count: @user.errors.count) }
            ul(class: "ml-6 list-disc space-y-1 text-sm") do
              @user.errors.each { |error| li { error.full_message } }
            end
          end
        end

        div(class: "space-y-2") do
          render RubyUI::FormFieldLabel.new(for: :oauth_name) { User.human_attribute_name(:name) }
          input(type: "text", id: "oauth_name", value: @name, readonly: true, class: input_classes)
        end

        div(class: "space-y-2") do
          render RubyUI::FormFieldLabel.new(for: :oauth_email) { User.human_attribute_name(:email) }
          input(type: "email", id: "oauth_email", value: @email, readonly: true, class: input_classes)
        end

        div(class: "space-y-2") do
          render RubyUI::FormFieldLabel.new(for: :user_username) { User.human_attribute_name(:username) }
          form.text_field :username,
                          required: true,
                          value: @user.username,
                          placeholder: t("helpers.placeholder.user.username"),
                          class: input_classes
        end

        render RubyUI::Button.new(type: "submit", variant: :primary, size: :lg, class: "w-full sm:w-auto") do
          t("users.oauth_signup.submit")
        end
      end
    end
  end

  private

  def input_classes
    "block w-full rounded-md border border-border-muted bg-surface-muted px-3 py-2 text-content shadow-sm focus:outline-none focus:ring-2 focus:ring-brand"
  end
end
