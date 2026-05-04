# frozen_string_literal: true

class Components::Posts::PostCard < Components::Base
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  def initialize(post:, depth: 0, liked: nil, show_actions: true, show_reply_badge: true)
    @post = post
    @depth = depth
    @liked = liked
    @show_actions = show_actions
    @show_reply_badge = show_reply_badge
  end

  def view_template
    div(
      id: dom_id(@post),
      class: wrapper_classes,
      data: {
        controller: "feed-reply",
        feed_reply_parent_id_value: @post.id,
        feed_reply_author_name_value: author_name,
        feed_reply_body_preview_value: body_preview
      }
    ) do
      render RubyUI::Card.new(class: "bg-surface border-border-muted shadow-sm hover:border-border-strong transition-all duration-200") do
        render RubyUI::CardContent.new(class: "p-4 sm:p-5 space-y-3") do
          post_header
          post_body
          post_actions if @show_actions
        end
      end
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
    parent_reply_badge if @show_reply_badge && @post.parent.present?

    div(class: "flex items-center gap-3") do
      render Components::UserAvatar.new(
        user: @post.user,
        federails_actor: @post.federails_actor,
        name: author_name,
        size: "h-8 w-8 sm:h-10 sm:w-10"
      )

      div(class: "flex-1 min-w-0") do
        span(class: "font-semibold text-content text-sm") { author_name }
        link_to(post_path(@post), class: "block text-xs text-content-muted hover:text-content transition-colors") do
          time(
            datetime: @post.created_at.iso8601,
            title: I18n.l(@post.created_at, format: :long)
          ) do
            plain "#{view_context.time_ago_in_words_korean(@post.created_at)} 전"
          end
        end
      end
    end
  end

  def parent_reply_badge
    render RubyUI::Badge.new(
      variant: :secondary,
      size: :sm,
      class: "mb-2 inline-flex items-center gap-1.5"
    ) do
      Hero::ArrowUturnLeft(variant: :outline, class: "w-3 h-3")
      plain "#{parent_author_name}님에게 답글"
    end
  end

  def post_body
    div(class: "text-content leading-relaxed wrap-break-word prose prose-sm dark:prose-invert max-w-none") do
      raw @post.body.html_safe
    end
    post_tags if post_tag_names.any?
    media_attachments if @post.media_attachments.any?
    article_preview if @post.article.present?
  end

  def post_tags
    div(class: "flex flex-wrap gap-1 mt-1") do
      post_tag_names.each do |tag|
        span(class: "text-xs text-link hover:text-link-hover hover:underline cursor-pointer transition-colors") { plain "##{tag}" }
      end
    end
  end

  def post_tag_names
    @post_tag_names ||= @post.tags.map(&:name)
  end

  def media_attachments
    attachments = @post.media_attachments.select { |a| a["url"].present? }
    return if attachments.empty?

    grid_class = attachments.size == 1 ? "grid-cols-1" : "grid-cols-2"

    render RubyUI::Dialog.new do
      render RubyUI::DialogTrigger.new(class: "contents") do
        div(class: "grid #{grid_class} gap-1 rounded-xl overflow-hidden mt-2 cursor-pointer") do
          attachments.each do |attachment|
            img(
              src: attachment["url"],
              alt: attachment["name"].to_s,
              class: "w-full object-cover max-h-72 bg-surface-muted hover:opacity-90 transition-opacity",
              loading: "lazy"
            )
          end
        end
      end

      render RubyUI::DialogContent.new(class: "max-w-3xl w-full px-15") do
        render RubyUI::DialogMiddle.new do
          render RubyUI::Carousel.new(options: { loop: true }, class: "w-full") do
            render RubyUI::CarouselContent.new do
              attachments.each do |attachment|
                render RubyUI::CarouselItem.new do
                  img(
                    src: attachment["url"],
                    alt: attachment["name"].to_s,
                    class: "w-full rounded-md object-contain max-h-[70vh]",
                    loading: "lazy"
                  )
                end
              end
            end
            render RubyUI::CarouselPrevious.new if attachments.size > 1
            render RubyUI::CarouselNext.new if attachments.size > 1
          end
        end
      end
    end
  end

  def post_actions
    div(class: "flex items-center gap-4 text-sm text-content-muted") do
      render Components::Likes::Button.new(likeable: @post, liked: @liked)

      render RubyUI::Button.new(
        variant: :ghost,
        size: :sm,
        data: { action: "feed-reply#activate" },
        class: "inline-flex items-center gap-1 text-content-muted hover:text-info-text transition-colors hover:bg-transparent p-0"
      ) do
        Hero::ChatBubbleLeft(variant: :outline, class: "w-4 h-4")
        if @post.children_count.positive?
          span { @post.children_count.to_s }
        end
      end
    end
  end

  def article_preview
    article = @post.article

    render RubyUI::Card.new(class: "bg-surface-muted border-border-muted shadow-none overflow-hidden") do
      render RubyUI::CardContent.new(class: "p-4 space-y-3") do
        div(class: "flex items-center gap-2 text-xs text-content-muted") do
          Hero::Newspaper(variant: :outline, class: "w-4 h-4")
          plain "연결된 기사"
        end

        div(class: "space-y-1") do
          h3(class: "text-sm font-semibold text-content leading-snug") do
            link_to(article_preview_title(article), article_path(article), class: "hover:text-link-hover")
          end

          if show_original_title?(article)
            p(class: "text-xs text-content-secondary wrap-break-word") { article.title }
          end
        end

        if article_preview_summary(article).present?
          p(class: "text-sm text-content-secondary leading-relaxed") { article_preview_summary(article) }
        end

        div(class: "flex flex-wrap items-center gap-3 text-xs text-content-muted") do
          if article.host.present?
            span(class: "inline-flex items-center gap-1") do
              Hero::GlobeAlt(variant: :outline, class: "w-3 h-3")
              plain article.host
            end
          end

          if article.published_at.present?
            span(class: "inline-flex items-center gap-1") do
              Hero::CalendarDays(variant: :outline, class: "w-3 h-3")
              plain I18n.l(article.published_at, format: :short)
            end
          end
        end
      end
    end
  end

  def author_name
    @post.user&.name || @post.federails_actor&.name || "알 수 없음"
  end

  def parent_author_name
    @post.parent.user&.name || @post.parent.federails_actor&.name || "알 수 없음"
  end


  def body_preview
    view_context.truncate(view_context.strip_tags(@post.body.to_s).squish, length: 120)
  end

  def article_preview_title(article)
    article.title_ko.presence || article.title.presence || "기사 보기"
  end

  def show_original_title?(article)
    article.title_ko.present? && article.title.present? && article.title_ko != article.title
  end

  def article_preview_summary(article)
    case article.summary_key
    when Array
      article.summary_key.first
    when String
      article.summary_key
    end
  end
end
