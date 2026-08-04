# typed: true
# frozen_string_literal: true

class Components::Users::Form::NewFields < Components::Base
  include Components::Users::Form::InputStyling

  def initialize(form:, user:)
    @form = form
    @user = user
  end

  def view_template
    form = @form
    div(class: "space-y-8 pt-8 border-t border-border-subtle/60") do
      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :user_username) { ::User.human_attribute_name(:username) }
        form.text_field :username, class: input_classes(@user.errors[:username]), placeholder: t("helpers.placeholder.user.username"), autocomplete: "username", required: true
        @user.errors[:username].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :user_email) { ::User.human_attribute_name(:email) }
        form.email_field :email, class: input_classes(@user.errors[:email]), autocomplete: "email", required: true
        @user.errors[:email].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :user_name) { t("users.form.optional_name_label") }
        form.text_field :name, class: input_classes(@user.errors[:name]), autocomplete: "name"
        @user.errors[:name].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end
      end
    end
  end
end
