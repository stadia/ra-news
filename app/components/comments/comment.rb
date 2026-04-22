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
      render RubyUI::Card.new(id: dom_id(@comment), class: "bg-surface-muted rounded-lg border-border-muted hover:border-border-strong transition-all duration-200 overflow-hidden") do
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
    end
  end

  def comment_header
    div(class: "flex items-center justify-between mb-3") do
      div(class: "flex items-center space-x-3") do
        render Components::UserAvatar.new(
          user: @comment.user,
          federails_actor: @comment.federails_actor,
          name: @comment.author_name
        )
        author_info
      end
      delete_button
    end
  end


  def author_info
    div do
      div(class: "text-sm font-medium text-content") { plain @comment.author_name }
      div(class: "text-xs text-content-muted flex items-center") do
        Hero::Clock(variant: :outline, class: "w-3 h-3 mr-1")
        plain "#{view_context.time_ago_in_words_korean(@comment.created_at)} 전"
      end
    end
  end

  def delete_button
    if view_context.user_signed_in? && @comment.user == view_context.current_user
      button_to(
        article_post_path(@article, @comment),
        method: :delete,
        data: { turbo_confirm: "정말 삭제하시겠습니까?" },
        form: { data: { turbo_stream: true } },
        class: "inline-flex items-center px-3 py-1 text-xs font-medium text-danger-text hover:text-danger-text-hover hover:bg-danger-solid/10 rounded-md transition-colors duration-200"
      ) do
        Hero::Trash(variant: :outline, class: "w-4 h-4 mr-1")
        plain "삭제"
      end
    end
  end

  def comment_body
    div(class: "text-content-secondary leading-relaxed prose prose-sm dark:prose-invert max-w-none") do
      raw @comment.body.html_safe
    end
  end

  def reply_button
    return unless view_context.user_signed_in?

    div(class: "mt-3 flex items-center justify-between text-sm") do
      render RubyUI::Button.new(
        variant: :ghost,
        data: { action: "reply-form#toggle" },
        class: "inline-flex items-center text-content-muted hover:text-link-hover transition-colors hover:bg-transparent") do
        Hero::ChatBubbleLeft(variant: :outline, class: "w-4 h-4 mr-1")
        plain "답글"
      end
    end
  end

  def reply_form_section
    div(class: "bg-surface/50") do
      render Components::Comments::CommentReplyForm.new(
        article: @article,
        comment: ::Post.new,
        parent_comment: @comment
      )
    end
  end

  def children_section
    div(id: "post_replies_#{@comment.id}", class: "ml-8 mr-3 mt-2 space-y-2 pb-3") do
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
