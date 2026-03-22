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
    form_with(model: @user, class: "contents", url: users_path, method: @user.persisted? ? :put : :post) do |form|
      render RubyUI::Card.new(class: "w-full max-w-2xl bg-app/40 border-border-subtle rounded-2xl overflow-hidden shadow-2xl my-6") do
        # Decorative Header
        div(class: "h-24 bg-linear-to-r from-surface to-surface-muted/50 border-b border-border-subtle")

        render RubyUI::CardContent.new(class: "px-6 pb-8 sm:px-10 sm:pb-10 pt-0") do
          # Avatar & Primary Identity Section (Visual only)
          div(class: "flex flex-col sm:flex-row items-center sm:items-end gap-6 -mt-12 mb-10") do
            render RubyUI::Avatar.new(size: :xl, class: "h-24 w-24 ring-4 ring-app bg-app shadow-xl") do
              render RubyUI::AvatarFallback.new(class: "bg-brand-solid text-brand-foreground text-3xl font-bold") do
                initials
              end
            end

            div(class: "text-center sm:text-left pb-1 flex-1") do
              h2(class: "text-3xl font-bold text-content tracking-tight") { @user.persisted? ? "정보 수정" : "회원 가입" }
              p(class: "text-content-muted font-medium text-lg mt-1") { @user.email_address_was || "새로운 시작" }
            end
          end

          # Error Messages
          if @user.errors.any?
            div(id: "error_explanation", class: "mb-8 p-4 bg-danger-solid/10 border border-danger-solid/20 rounded-xl text-danger-text") do
              h2(class: "font-bold mb-2 flex items-center gap-2") do
                Hero::ExclamationCircle(variant: :outline, class: "w-[18px] h-[18px]")
                plain pluralize(@user.errors.count, "error") + " prohibited this user from being saved:"
              end
              ul(class: "list-disc ml-6 space-y-1 text-sm") do
                @user.errors.each { |error| li { error.full_message } }
              end
            end
          end

          # Form Fields Grid
          div(class: "grid grid-cols-1 md:grid-cols-2 gap-x-12 gap-y-8 pt-8 border-t border-border-subtle/60") do
            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new(for: :user_email_address) { "이메일 주소" }
              form.email_field :email_address, class: input_classes(@user.errors[:email_address])
              @user.errors[:email_address].each do |msg|
                render RubyUI::FormFieldError.new { msg }
              end
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new(for: :user_name) { "사용자 이름" }
              form.text_field :name, class: input_classes(@user.errors[:name])
              @user.errors[:name].each do |msg|
                render RubyUI::FormFieldError.new { msg }
              end
            end
          end

          # Submit Button
          div(class: "mt-10 pt-8 border-t border-border-subtle/60 flex items-center justify-end gap-3") do
            if @user.persisted?
              render RubyUI::Link.new(
                href: users_path,
                class: "flex items-center justify-center gap-2 rounded-xl bg-surface hover:bg-surface-muted text-content font-bold text-sm border border-border-strong transition-all active:scale-95 shadow-lg"
              ) do
                Hero::ChevronLeft(variant: :outline, class: "w-4 h-4")
                plain "돌아가기"
              end
            end

            render RubyUI::Button.new(
              type: "submit",
              class: "group relative flex items-center justify-center gap-2 rounded-xl bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground font-bold text-sm transition-all active:scale-95 shadow-lg shadow-brand/20"
            ) do
              plain @user.persisted? ? "변경사항 저장" : "가입하기"
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
    (@user.name.presence || @user.email_address.presence || "U").first.upcase
  end
end
