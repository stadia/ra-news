# frozen_string_literal: true

class Views::Users::New < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def initialize(user:)
    @user = user
  end

  def view_template
    content_for :title, "회원 가입"

    div(class: "space-y-6 max-w-6xl mx-auto") do
      render RubyUI::Heading.new(level: 1, class: "font-bold") { "회원 가입" }
      render Components::Users::Form.new(user: @user)
      render RubyUI::Link.new(
        href: new_session_path,
        size: :lg,
        class: "w-full sm:w-auto text-center rounded-md bg-slate-700 hover:bg-slate-600 text-slate-100 inline-block font-medium focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2 focus:ring-offset-slate-900"
      ) { "뒤로" }
    end
  end
end
