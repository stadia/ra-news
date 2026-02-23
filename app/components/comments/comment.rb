# frozen_string_literal: true

class Components::Comments::Comment < Components::Base
  include Phlex::Rails::Helpers::ButtonTo
  include PhlexIcons
  include Phlex::Rails::Helpers::DOMID

  def initialize(comment:, article:, depth: 0, children: {})
    @comment = comment
    @article = article
    @depth = depth
    @children = children
  end

  def view_template
    div(class: wrapper_classes, data: { controller: "reply-form" }) do
      div(id: dom_id(@comment), class: "bg-gray-700 rounded-lg border border-gray-600 hover:border-gray-500 transition-all duration-200 overflow-hidden") do
        comment_content
        reply_form_section if can_reply?
        children_section if can_reply?
      end
    end
  end

  private

  def wrapper_classes
    return "" if @depth.zero?

    "relative"
  end

  def can_reply?
    @depth.zero?
  end

  def comment_content
    div(class: "p-4 lg:p-5") do
      comment_header
      comment_body
      reply_button if can_reply?
      guest_delete_modal if @comment.persisted? && @comment.guest?
    end
  end

  def comment_header
    div(class: "flex items-center justify-between mb-3") do
      div(class: "flex items-center space-x-3") do
        render RubyUI::Avatar.new(class: "h-8 w-8 shrink-0") do
          render RubyUI::AvatarFallback.new(class: "bg-linear-to-r from-blue-500 to-purple-600 text-white text-sm font-bold") do
            plain @comment.author_name.to_s.first.to_s.upcase
          end
        end
        author_info
      end
      delete_button
    end
  end

  def author_info
    div do
      div(class: "text-sm font-medium text-gray-200") do
        plain @comment.author_name
        if @comment.guest?
          span(class: "ml-2 text-xs text-gray-500") { "(게스트)" }
        end
      end
      div(class: "text-xs text-gray-400 flex items-center") do
        Hero::Clock(variant: :outline, class: "w-3 h-3 mr-1")
        plain "#{helpers.time_ago_in_words_korean(@comment.created_at)} 전"
      end
    end
  end

  def delete_button
    if @comment.guest?
      render RubyUI::Button.new(
        variant: :ghost,
        data: { controller: "modal", action: "modal#open", modal_id: "delete_comment_modal_#{@comment.id}" },
        class: "inline-flex items-center px-3 py-1 text-xs font-medium text-red-400 hover:text-red-300 hover:bg-red-900 hover:bg-opacity-20 rounded-md transition-colors duration-200 cursor-pointer") do
        Hero::Trash(variant: :outline, class: "w-4 h-4 mr-1")
        plain "삭제"
      end
    elsif helpers.authenticated? && @comment.user == Current.user
      button_to(
        helpers.article_comment_path(@article.slug, @comment),
        method: :delete,
        data: { turbo_confirm: "정말 삭제하시겠습니까?" },
        form: { data: { turbo_stream: true } },
        class: "inline-flex items-center px-3 py-1 text-xs font-medium text-red-400 hover:text-red-300 hover:bg-red-900 hover:bg-opacity-20 rounded-md transition-colors duration-200"
      ) do
        Hero::Trash(variant: :outline, class: "w-4 h-4 mr-1")
        plain "삭제"
      end
    end
  end

  def comment_body
    div(class: "text-gray-300 leading-relaxed") do
      helpers.simple_format(ERB::Util.h(@comment.body), {}, wrapper_tag: "div")
    end
  end

  def reply_button
    div(class: "mt-3 flex items-center justify-between text-sm") do
      render RubyUI::Button.new(
        variant: :ghost,
        data: { action: "reply-form#toggle" },
      class: "inline-flex items-center text-gray-400 hover:text-blue-400 transition-colors hover:bg-transparent") do
        Hero::ChatBubbleLeft(variant: :outline, class: "w-4 h-4 mr-1")
        plain "답글"
      end
    end
  end

  def guest_delete_modal
    render Components::Comments::DeleteModal.new(article: @article, comment: @comment)
  end

  def reply_form_section
    div(class: "bg-gray-800/50") do
      render Components::Comments::CommentReplyForm.new(
        article: @article,
        comment: ::Comment.new,
        parent_comment: @comment
      )
    end
  end

  def children_section
    div(id: "comment_replies_#{@comment.id}", class: "ml-8 mr-3 mt-2 space-y-2 pb-3") do
      @children.each do |child, grandchildren|
        render Components::Comments::Comment.new(
          comment: child,
          article: @article,
          depth: @depth + 1,
          children: grandchildren
        )
      end
    end
  end
end
