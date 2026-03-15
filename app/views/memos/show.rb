# frozen_string_literal: true

class Views::Memos::Show < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include PhlexIcons

  def initialize(memo:, comments:, comment:)
    @memo = memo
    @comments = comments
    @comment = comment
  end

  def view_template
    content_for :title, @memo.body.truncate(50)

    div(class: "space-y-6 max-w-2xl mx-auto", id: dom_id(@memo)) do
      memo_section
      comments_section
    end
  end

  private

  def memo_section
    article(class: "bg-gray-800 rounded-xl shadow-lg overflow-hidden border border-gray-700") do
      div(class: "p-5 sm:p-6") do
        memo_meta
        memo_body
        memo_actions
      end
    end
  end

  def memo_meta
    div(class: "flex items-center justify-between mb-4") do
      div(class: "flex items-center gap-3") do
        div(class: "w-8 h-8 bg-green-600 rounded-full flex items-center justify-center") do
          span(class: "text-white text-sm font-bold") { @memo.user.name.to_s.first.upcase }
        end
        div do
          div(class: "text-sm font-medium text-gray-200") { @memo.user.name }
          div(class: "text-xs text-gray-400") do
            Hero::Clock(variant: :outline, class: "w-3 h-3 inline mr-1")
            plain "#{view_context.time_ago_in_words_korean(@memo.created_at)} 전"
          end
        end
      end
      if view_context.authenticated? && @memo.user == Current.user
        delete_button
      end
    end
  end

  def memo_body
    div(class: "text-gray-100 text-base leading-relaxed whitespace-pre-wrap mb-4") do
      plain @memo.body
    end
  end

  def memo_actions
    div(class: "flex items-center gap-4 text-sm text-gray-400 border-t border-gray-700 pt-4") do
      span(class: "flex items-center gap-1") do
        Hero::ChatBubbleLeft(variant: :outline, class: "w-4 h-4")
        plain "#{@memo.comments_count}개의 댓글"
      end
      if @memo.federated_url.present?
        span(class: "flex items-center gap-1") do
          Hero::GlobeAlt(variant: :outline, class: "w-4 h-4 text-green-500")
          span(class: "text-green-500") { "Fediverse 공유됨" }
        end
      end
    end
  end

  def delete_button
    form(action: memo_path(@memo), method: :post, data: { turbo_confirm: "정말 삭제하시겠습니까?" }) do
      input(type: "hidden", name: "_method", value: "delete")
      input(type: "hidden", name: view_context.form_authenticity_token_name, value: view_context.form_authenticity_token)
      button(
        type: "submit",
        class: "inline-flex items-center px-3 py-1 text-xs font-medium text-red-400 hover:text-red-300 hover:bg-red-900/20 rounded-md transition-colors"
      ) do
        Hero::Trash(variant: :outline, class: "w-4 h-4 mr-1")
        plain "삭제"
      end
    end
  end

  def comments_section
    section(class: "bg-gray-800 rounded-xl shadow-lg overflow-hidden border border-gray-700") do
      div(class: "p-5 sm:p-6") do
        render RubyUI::Heading.new(level: 3, class: "font-bold text-gray-100 mb-6 flex items-center", id: :comments_header) do
          render(Components::Comments::CommentHeader.new(comments: @comments))
        end
        div(id: "comment_form", class: "border-t border-gray-700 mb-4") do
          render Components::Memos::MemoCommentForm.new(memo: @memo, comment: @comment)
        end
        div(class: "space-y-4 pt-6") do
          render Components::Memos::MemoComments.new(memo: @memo, comments: @comments)
        end
      end
    end
  end
end
