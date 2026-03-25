# frozen_string_literal: true

class Views::Sessions::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def view_template
    div(class: "space-y-6 max-w-6xl mx-auto") do
      render RubyUI::Heading.new(level: 1, class: "font-bold") { "로그인" }

      form_with(url: user_session_path, scope: :user, class: "contents") do |form|
        render RubyUI::FormField.new(class: "my-5") do
          render RubyUI::FormFieldLabel.new(for: :email) { "이메일" }
          form.email_field :email,
                           required: true,
                           autofocus: true,
                           autocomplete: "username",
                           placeholder: "email 주소",
                           value: view_context.params[:email],
                           class: "block shadow-sm rounded-md border border-border-muted px-3 py-2 mt-2 w-full bg-surface-muted text-content placeholder:text-content-muted focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent transition-colors duration-200"
        end

        render RubyUI::FormField.new(class: "my-5") do
          render RubyUI::FormFieldLabel.new(for: :password) { "비밀번호" }
          form.password_field :password,
                              required: true,
                              autocomplete: "current-password",
                              placeholder: "비밀번호",
                              maxlength: 72,
                              class: "block shadow-sm rounded-md border border-border-muted px-3 py-2 mt-2 w-full bg-surface-muted text-content placeholder:text-content-muted focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent transition-colors duration-200"
        end

        div(class: "col-span-6 sm:flex sm:items-center sm:gap-4") do
          div(class: "inline") do
            render RubyUI::Button.new(
              type: "submit",
              variant: :primary,
              size: :lg,
              class: "w-full sm:w-auto rounded-md bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-brand focus:ring-offset-2 focus:ring-offset-app"
            ) { "로그인" }
          end

          div(class: "inline") do
            render RubyUI::Link.new(
              href: new_user_registration_path,
              variant: :primary,
              size: :lg,
              class: "w-full sm:w-auto text-center rounded-md bg-surface-muted hover:bg-surface-hover text-content inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-brand focus:ring-offset-2 focus:ring-offset-app"
            ) { "회원 가입" }
          end

          div(class: "inline") do
            render RubyUI::Link.new(
              href: new_user_password_path,
              variant: :primary,
              size: :lg,
              class: "w-full sm:w-auto text-center rounded-md text-content-muted hover:text-content inline-block font-medium cursor-pointer focus:outline-none"
            ) { "비밀번호를 잊으셨나요?" }
          end
        end
      end
    end
  end
end
