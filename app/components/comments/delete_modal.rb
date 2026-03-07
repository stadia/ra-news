# frozen_string_literal: true

class Components::Comments::DeleteModal < Components::Base
  include Phlex::Rails::Helpers::Truncate
  include Phlex::Rails::Helpers::FormWith
  include PhlexIcons

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
      div(class: "fixed inset-0 bg-slate-900/75 transition-opacity", data: { action: "click->modal#close" }) do
      end
      div(class: "flex min-h-full items-center justify-center p-4 text-center sm:p-0") do
        div(class: "relative transform overflow-hidden rounded-lg bg-slate-800 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg border border-slate-700") do
          # Modal header
          div(class: "bg-slate-800 px-4 py-3 sm:px-6 border-b border-slate-700") do
            h3(class: "text-base font-semibold leading-6 text-slate-100", id: "modal-title") do
              Hero::ShieldExclamation(variant: :outline, class: "w-5 h-5 inline mr-2 text-yellow-400")
              plain "댓글 삭제 확인"
            end
          end
          # Modal body
          div(class: "px-4 py-5 sm:p-6") do
            div(class: "mb-4") do
              p(class: "text-sm text-slate-300 mb-2") do
                "게스트 댓글을 삭제하려면 작성 시 입력한 비밀번호를 입력해주세요."
              end
              p(class: "text-sm text-slate-400") do
                "댓글 내용: #{truncate(@comment.body, length: 50)}"
              end
            end
            form_with url: verify_password_article_comment_path(@article, @comment),
                        method: :post, local: false, class: "space-y-4" do |f|
                          div(class: "space-y-2") do
                            f.label :password, "비밀번호", class: "block text-sm font-medium text-slate-300"
                            f.password_field :password,
                                                        required: true,
                                                        class:
                                                          "w-full px-3 py-2 rounded-lg border border-slate-600 bg-slate-700 text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors duration-200",
                                                        placeholder: "비밀번호를 입력하세요"
                          end
                          div(class: "flex gap-3 mt-5 sm:mt-6") do
                            render RubyUI::Button.new(variant: :ghost, size: :xl, data: { action: "modal#close" },
                              class: "flex-1 rounded-md bg-slate-700 hover:bg-slate-600 text-slate-100 inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2 focus:ring-offset-slate-900") { "취소" }
                            f.submit "삭제", class: "flex-1 rounded-md px-3.5 py-2.5 bg-red-600 hover:bg-red-700 text-white inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 focus:ring-offset-slate-900"
                          end
            end
          end
        end
      end
    end
  end
end
