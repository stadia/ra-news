# frozen_string_literal: true

class Components::Comments::DeleteModal < Components::Base
  include Phlex::Rails::Helpers::Truncate
  include Phlex::Rails::Helpers::FormWith

  def initialize(article:, comment:)
    @article = article
    @comment = comment
  end

  def view_template
    div(id: "delete_comment_modal_#{@comment.id}",
      class: "hidden fixed inset-0 z-50 overflow-y-auto",
      "aria-labelledby": "modal-title",
      role: "dialog",
      "aria-modal": "true",
      data: { controller: "modal", modal_id: "delete_comment_modal_#{@comment.id}" }) do
      # Background backdrop
      div(class: "fixed inset-0 bg-gray-900 bg-opacity-75 transition-opacity", data: { action: "click->modal#close" }) do
      end
      div(class: "flex min-h-full items-center justify-center p-4 text-center sm:p-0") do
        div(class: "relative transform overflow-hidden rounded-lg bg-gray-800 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg") do
          # Modal header
          div(class: "bg-gray-700 px-4 py-3 sm:px-6 border-b border-gray-600") do
            h3(class: "text-base font-semibold leading-6 text-gray-100", id: "modal-title") do
              helpers.heroicon("shield-exclamation", variant: :outline,
                        options: { class: "w-5 h-5 inline mr-2 text-yellow-400" })
              "댓글 삭제 확인"
            end
          end
          # Modal body
          div(class: "px-4 py-5 sm:p-6") do
            div(class: "mb-4") do
              p(class: "text-sm text-gray-300 mb-2") do
                "게스트 댓글을 삭제하려면 작성 시 입력한 비밀번호를 입력해주세요."
              end
              p(class: "text-sm text-gray-300") do
                "댓글 내용: #{truncate(@comment.body, length: 50)}"
              end
            end
            form_with url: verify_password_article_comment_path(@article.slug, @comment),
                        method: :post, local: false, class: "space-y-4" do |f|
                          div(class: "space-y-2") do
                            f.label :password, "비밀번호", class: "block text-sm font-medium text-gray-300"
                            f.password_field :password,
                                                        required: true,
                                                        class:
                                                          "w-full px-3 py-2 rounded-lg border border-gray-600 bg-white text-gray-900 placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent",
                                                        placeholder: "비밀번호를 입력하세요"
                          end
                          div(class: "flex gap-3 mt-5 sm:mt-6") do
                            button(type: "button",
                                  data: { action: "modal#close" },
                                  class: "flex-1 px-4 py-2 text-sm font-medium text-gray-300 bg-gray-700 border
                                  border-gray-600 rounded-lg hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500") do
                              "취소"
                            end
                            f.submit "삭제", class: "flex-1 px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
                          end
            end
          end
        end
      end
    end
  end
end
