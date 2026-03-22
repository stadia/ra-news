# frozen_string_literal: true

class Components::Posts::PostCard < Components::Base
  include Phlex::Rails::Helpers::DOMID
  include PhlexIcons

  def initialize(post:, depth: 0, liked: nil)
    @post = post
    @depth = depth
    @liked = liked
  end

  def view_template
    div(
      id: dom_id(@post),
      class: wrapper_classes,
      data: { controller: "reply-form" }
    ) do
      render RubyUI::Card.new(class: "bg-surface border-border-muted shadow-sm hover:border-border-strong transition-all duration-200") do
        render RubyUI::CardContent.new(class: "p-4 sm:p-5 space-y-3") do
          post_header
          post_body
          post_actions if @depth.zero?
        end
      end
      reply_form_section if @depth.zero?
    end
  end

  private

  def wrapper_classes
    classes = []
    if @depth.positive?
      classes << "ml-4 sm:ml-8 border-l-2 border-border-muted pl-3 sm:pl-4"
    end
    classes.join(" ")
  end

  def post_header
    div(class: "flex items-center gap-3") do
      render RubyUI::Avatar.new(class: "h-8 w-8 sm:h-10 sm:w-10 shrink-0") do
        render RubyUI::AvatarFallback.new(class: "bg-linear-to-r from-info-solid to-brand-solid text-brand-foreground text-sm font-bold") do
          plain author_name.first.to_s.upcase
        end
      end

      div(class: "flex-1 min-w-0") do
        span(class: "font-semibold text-content text-sm") { author_name }
        time(
          class: "block text-xs text-content-muted",
          datetime: @post.created_at.iso8601,
          title: I18n.l(@post.created_at, format: :long)
        ) do
          plain "#{view_context.time_ago_in_words_korean(@post.created_at)} 전"
        end
      end
    end
  end

  def post_body
    p(class: "text-content leading-relaxed wrap-break-word whitespace-pre-wrap") do
      plain @post.body
    end
  end

  def post_actions
    div(class: "flex items-center gap-4 text-sm text-content-muted") do
      render Components::Likes::Button.new(likeable: @post, liked: @liked)

      render RubyUI::Button.new(
        variant: :ghost,
        size: :sm,
        data: { action: "reply-form#toggle" },
        class: "inline-flex items-center gap-1 text-content-muted hover:text-info-text transition-colors hover:bg-transparent p-0"
      ) do
        Hero::ChatBubbleLeft(variant: :outline, class: "w-4 h-4")
        if @post.children_count.positive?
          span { @post.children_count.to_s }
        end
      end
    end
  end

  def reply_form_section
    div(data: { reply_form_target: "form" }, class: "hidden mt-2") do
      render Components::Posts::ReplyForm.new(parent_post: @post)
    end
  end

  def author_name
    @post.user&.name || @post.federails_actor&.name || "알 수 없음"
  end
end
