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
        div(class: "my-5") do
          f.password_field :password,
            required: true,
            autocomplete: "new-password",
            placeholder: "새 비밀번호를 입력하세요",
            maxlength: 72,
            class: "block shadow-sm rounded-md border border-slate-600 px-3 py-2 mt-2 w-full bg-slate-700 text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors duration-200"
        end

        div(class: "my-5") do
          f.password_field :password_confirmation,
            required: true,
            autocomplete: "new-password",
            placeholder: "새 비밀번호를 다시 입력하세요",
            maxlength: 72,
            class: "block shadow-sm rounded-md border border-slate-600 px-3 py-2 mt-2 w-full bg-slate-700 text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors duration-200"
        end

        div(class: "inline") do
          render RubyUI::Button.new(
            type: "submit",
            variant: :primary,
            size: :lg,
            class: "w-full sm:w-auto rounded-md bg-green-500 hover:bg-green-600 text-white inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900"
          ) { "저장" }
        end
      end
    end
  end
end
