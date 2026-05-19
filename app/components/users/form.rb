# frozen_string_literal: true

class Components::Users::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::Pluralize
  include Phlex::Rails::Helpers::DOMID
  include PhlexIcons

  def initialize(user:)
    @user = user
  end

  def view_template
    form_with(model: @user, class: "contents", url: user_registration_path, method: @user.persisted? ? :put : :post) do |form|
      render RubyUI::Card.new(class: "w-full max-w-2xl bg-app/40 border-border-subtle rounded-2xl overflow-hidden shadow-2xl my-6") do
        # Decorative Header
        div(class: "h-24 bg-linear-to-r from-surface to-surface-muted/50 border-b border-border-subtle")

        render RubyUI::CardContent.new(class: "px-6 pb-8 sm:px-10 sm:pb-10 pt-0") do
          # Avatar & Primary Identity Section (Visual only)
          div(class: "flex flex-col sm:flex-row items-center sm:items-end gap-6 -mt-12 mb-10") do
            render RubyUI::Avatar.new(size: :xl, class: "h-24 w-24 ring-4 ring-app bg-app shadow-xl") do
              if avatar_url
                render RubyUI::AvatarImage.new(src: avatar_url, alt: avatar_alt)
              else
                render RubyUI::AvatarFallback.new(class: "bg-brand-solid text-brand-foreground text-3xl font-bold") do
                  initials
                end
              end
            end

            div(class: "text-center sm:text-left pb-1 flex-1") do
              h2(class: "text-3xl font-bold text-content tracking-tight") { @user.persisted? ? t("users.form.edit_heading") : t("users.form.sign_up_heading") }
              p(class: "text-content-muted font-medium text-lg mt-1") { @user.email || t("users.form.new_beginning") }
            end
          end

          # Error Messages
          if @user.errors.any?
            div(id: "error_explanation", class: "mb-8 p-4 bg-danger-solid/10 border border-danger-solid/20 rounded-xl text-danger-text") do
              h2(class: "font-bold mb-2 flex items-center gap-2") do
                Hero::ExclamationCircle(variant: :outline, class: "w-[18px] h-[18px]")
                plain t("errors.messages.form_errors", count: @user.errors.count)
              end
              ul(class: "list-disc ml-6 space-y-1 text-sm") do
                @user.errors.each { |error| li { error.full_message } }
              end
            end
          end

          if @user.persisted?
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
          else
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

          unless @user.persisted?
            div(class: "space-y-8 pt-8") do
              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new(for: :user_password) { ::User.human_attribute_name(:password) }
                form.password_field :password, class: input_classes(@user.errors[:password]), autocomplete: "new-password"
                @user.errors[:password].each do |msg|
                  render RubyUI::FormFieldError.new { msg }
                end
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new(for: :user_password_confirmation) { ::User.human_attribute_name(:password_confirmation) }
                form.password_field :password_confirmation, class: input_classes(@user.errors[:password_confirmation]), autocomplete: "new-password"
                @user.errors[:password_confirmation].each do |msg|
                  render RubyUI::FormFieldError.new { msg }
                end
              end
            end
          end

          # Submit Button
          div(class: "mt-10 pt-8 border-t border-border-subtle/60 flex items-center justify-end gap-3") do
            if @user.persisted?
              render RubyUI::Link.new(
                href: account_password_path,
                class: "flex items-center justify-center gap-2 rounded-xl bg-surface hover:bg-surface-muted text-content font-bold text-sm border border-border-strong transition-all active:scale-95 shadow-lg"
              ) do
                Hero::Key(variant: :outline, class: "w-4 h-4")
                plain t("users.form.change_password")
              end

              render RubyUI::Link.new(
                href: user_profile_path(@user),
                class: "flex items-center justify-center gap-2 rounded-xl bg-surface hover:bg-surface-muted text-content font-bold text-sm border border-border-strong transition-all active:scale-95 shadow-lg"
              ) do
                Hero::ChevronLeft(variant: :outline, class: "w-4 h-4")
                plain t("users.form.back")
              end
            end

            render RubyUI::Button.new(
              type: "submit",
              class: "group relative flex items-center justify-center gap-2 rounded-xl bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground font-bold text-sm transition-all active:scale-95 shadow-lg shadow-brand/20"
            ) do
              plain @user.persisted? ? t("users.form.save_changes") : t("users.form.sign_up_submit")
              Hero::ArrowLongRight(variant: :outline, class: "w-5 h-5 transition-transform group-hover:translate-x-1")
            end
          end
        end
      end
    end
  end

  private

  def input_classes(errors)
    base_classes = "block w-full bg-surface/50 border rounded-xl px-4 py-3 text-content placeholder:text-content-muted focus:outline-none focus:ring-2 transition-all duration-200"
    error_classes = errors.any? ? "border-destructive/50 focus:ring-destructive/30" : "border-border-strong focus:ring-brand/30 focus:border-brand/50"
    "#{base_classes} #{error_classes}"
  end

  def initials
    (@user.name.presence || @user.email.presence || "U").first.upcase
  end

  def avatar_alt
    @user.name.presence || @user.username.presence || @user.email.presence || t("users.form.avatar_alt_default")
  end

  def avatar_url
    @user.avatar_url
  end
end
