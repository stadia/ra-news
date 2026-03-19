# frozen_string_literal: true

class Views::Passwords::New < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith

  def view_template
    div(class: "mx-auto md:w-2/3 w-full") do
      render RubyUI::Heading.new(level: 1, class: "font-bold") { "비밀번호를 잊으셨나요?" }

      form_with(url: helpers.passwords_path, class: "contents") do |f|
        render RubyUI::FormField.new(class: "my-5") do
          render RubyUI::FormFieldLabel.new(for: :email_address) { "이메일" }
          f.email_field :email_address,
            required: true,
            autofocus: true,
            autocomplete: "username",
            placeholder: "이메일 주소를 입력하세요",
            value: helpers.params[:email_address],
            class: "block shadow-sm rounded-md border border-border-muted px-3 py-2 mt-2 w-full bg-surface-muted text-content placeholder:text-content-muted focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent transition-colors duration-200"
        end

        div(class: "inline") do
          render RubyUI::Button.new(
            type: "submit",
            variant: :primary,
            size: :lg,
            class: "w-full sm:w-auto rounded-md bg-brand hover:bg-brand-hover text-brand-foreground inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-brand focus:ring-offset-2 focus:ring-offset-app"
          ) { "재설정 메일 보내기" }
        end
      end
    end
  end
end
