# frozen_string_literal: true

class Views::Users::New < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def initialize(user:)
    @user = user
  end

  def view_template
    content_for :title, "회원 가입"

    div(class: "max-w-2xl mx-auto py-12 px-4 sm:px-6") do
      div(class: "mb-2 px-1") do
        render RubyUI::Heading.new(level: 1, class: "text-3xl font-bold text-content tracking-tight") { "회원 가입" }
        p(class: "mt-1 text-content-muted") { "새 계정을 만듭니다." }
      end

      render Components::Users::Form.new(user: @user)
    end
  end
end
