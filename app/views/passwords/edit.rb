# frozen_string_literal: true

class Views::Passwords::Edit < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith

  def initialize(token:)
    @token = token
  end

  def view_template
    div(class: "mx-auto md:w-2/3 w-full") do
      render RubyUI::Heading.new(level: 1, class: "font-bold") { "새 비밀번호 설정" }

      form_with(url: helpers.password_path(@token), method: :put, class: "contents") do |f|
        render RubyUI::FormField.new(class: "my-5") do
          render RubyUI::FormFieldLabel.new(for: :password) { "새 비밀번호" }
          f.password_field :password,
            required: true,
            autocomplete: "new-password",
            placeholder: "새 비밀번호를 입력하세요",
            maxlength: 72,
            class: "block shadow-sm rounded-md border border-border-muted px-3 py-2 mt-2 w-full bg-surface-muted text-content placeholder:text-content-muted focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent transition-colors duration-200"
        end

        render RubyUI::FormField.new(class: "my-5") do
          render RubyUI::FormFieldLabel.new(for: :password_confirmation) { "새 비밀번호 확인" }
          f.password_field :password_confirmation,
            required: true,
            autocomplete: "new-password",
            placeholder: "새 비밀번호를 다시 입력하세요",
            maxlength: 72,
            class: "block shadow-sm rounded-md border border-border-muted px-3 py-2 mt-2 w-full bg-surface-muted text-content placeholder:text-content-muted focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent transition-colors duration-200"
        end

        div(class: "inline") do
          render RubyUI::Button.new(
            type: "submit",
            variant: :primary,
            size: :lg,
            class: "w-full sm:w-auto rounded-md bg-brand hover:bg-brand-hover text-brand-foreground inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-brand focus:ring-offset-2 focus:ring-offset-app"
          ) { "저장" }
        end
      end
    end
  end
end
