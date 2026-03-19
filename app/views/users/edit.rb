# frozen_string_literal: true

class Views::Users::Edit < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include PhlexIcons

  def initialize(user:)
    @user = user
  end

  def view_template
    content_for :title, "사용자 정보 수정"

    div(class: "max-w-2xl mx-auto py-12 px-4 sm:px-6") do
      div(class: "mb-2 px-1") do
        render RubyUI::Heading.new(level: 1, class: "text-3xl font-bold text-white tracking-tight") { "사용자 정보 수정" }
        p(class: "mt-1 text-slate-400") { "계정 정보를 업데이트합니다." }
      end

      render Components::Users::Form.new(user: @user)
    end
  end
end
