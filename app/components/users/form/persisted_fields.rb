# frozen_string_literal: true

class Components::Users::Form::PersistedFields < Components::Base
  include Components::Users::Form::InputStyling

  def initialize(form:, user:)
    @form = form
    @user = user
  end

  def view_template
    form = @form
    div(class: "space-y-8 pt-8 border-t border-border-subtle/60") do
      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :user_avatar) { ::User.human_attribute_name(:avatar) }
        render RubyUI::FormFieldHint.new(class: "mb-3 text-content-muted") do
          t("users.form.avatar_hint")
        end
        form.file_field :avatar, class: input_classes(@user.errors[:avatar]), accept: "image/png,image/jpeg,image/webp,image/gif"
        @user.errors[:avatar].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end

        if @user.avatar_attached?
          label(for: :user_remove_avatar, class: "mt-4 inline-flex items-center gap-3 text-sm text-content-secondary cursor-pointer") do
            render RubyUI::Checkbox.new(id: :user_remove_avatar, name: "user[remove_avatar]", value: "1")
            span { t("users.form.remove_avatar") }
          end
        end
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :user_name) { ::User.human_attribute_name(:name) }
        form.text_field :name, class: input_classes(@user.errors[:name]), autocomplete: "name"
        @user.errors[:name].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :user_email) { ::User.human_attribute_name(:email) }
        form.email_field :email, class: input_classes(@user.errors[:email]), autocomplete: "email"
        @user.errors[:email].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :user_locale) { ::User.human_attribute_name(:locale) }
        form.select :locale,
          [ [ t("users.form.locale_options.ko"), "ko" ], [ t("users.form.locale_options.ja"), "ja" ], [ t("users.form.locale_options.en"), "en" ] ],
          { include_blank: t("users.form.locale_auto") },
          class: input_classes(@user.errors[:locale])
        @user.errors[:locale].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end
      end
    end
  end
end
