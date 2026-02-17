# frozen_string_literal: true

class Components::LoginRequired < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  def initialize(title: "로그인이 필요합니다", message: "댓글을 작성하거나 대화에 참여하려면 로그인이 필요합니다.")
    @title = title
    @message = message
  end

  def view_template
    div(class: "bg-gray-700 rounded-xl p-8 border border-gray-600 text-center") do
      div(class: "inline-flex items-center justify-center w-12 h-12 rounded-full bg-gray-600 mb-4") do
        Hero::LockClosed(variant: :outline, class: "w-6 h-6 text-gray-300")
      end

      h3(class: "text-lg font-medium text-gray-100 mb-2") { @title }
      p(class: "text-gray-400 mb-6") { @message }

      link_to(helpers.new_session_path, class: "inline-flex items-center px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors duration-200", data: { turbo: false }) do
        plain "로그인 하러 가기"
        Hero::ArrowRight(variant: :outline, class: "w-4 h-4 ml-2")
      end
    end
  end
end
