# frozen_string_literal: true

class Views::Passwords::Edit < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith

  def initialize(token:)
    @token = token
  end

  def view_template
    div(class: "mx-auto md:w-2/3 w-full") do
      render RubyUI::Heading.new(level: 1, class: "font-bold") { t("passwords.edit.heading") }

      form_with(url: user_password_path, method: :put, scope: :user, class: "contents") do |f|
        f.hidden_field :reset_password_token, value: @token
        render RubyUI::FormField.new(class: "my-5") do
          render RubyUI::FormFieldLabel.new(for: :password) { t("passwords.edit.password_label") }
          f.password_field :password,
            required: true,
            autocomplete: "new-password",
            placeholder: t("passwords.edit.password_placeholder"),
            maxlength: 72,
            class: "block shadow-sm rounded-md border border-border-muted px-3 py-2 mt-2 w-full bg-surface-muted text-content placeholder:text-content-muted focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent transition-colors duration-200"
        end

        render RubyUI::FormField.new(class: "my-5") do
          render RubyUI::FormFieldLabel.new(for: :password_confirmation) { t("passwords.edit.password_confirmation_label") }
          f.password_field :password_confirmation,
            required: true,
            autocomplete: "new-password",
            placeholder: t("passwords.edit.password_confirmation_placeholder"),
            maxlength: 72,
            class: "block shadow-sm rounded-md border border-border-muted px-3 py-2 mt-2 w-full bg-surface-muted text-content placeholder:text-content-muted focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent transition-colors duration-200"
        end

        div(class: "inline") do
          render RubyUI::Button.new(
            type: "submit",
            variant: :primary,
            size: :lg,
            class: "w-full sm:w-auto rounded-md bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-brand focus:ring-offset-2 focus:ring-offset-app"
          ) { t("passwords.edit.submit") }
        end
      end
    end
  end
end
