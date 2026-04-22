# frozen_string_literal: true

class Components::RecentCommentsSidebar < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::Truncate
  include PhlexIcons

  def initialize(recent_comments:)
    @recent_comments = recent_comments
  end

  def view_template
    aside(class: "recent-comments-sidebar") do
      h3(class: "text-lg font-semibold text-content mb-4 flex items-center gap-2") do
        Hero::ChatBubbleLeftRight(variant: :outline, class: "w-5 h-5 text-accent-text")
        plain "최근 댓글"
      end

      div(class: "space-y-3") do
        @recent_comments.each do |comment|
          comment_card(comment)
        end
      end
    end
  end

  private

  def comment_card(comment)
    render RubyUI::Card.new(class: "bg-surface p-3 border-border-strong hover:border-border-muted transition-colors rounded-lg") do
      div(class: "flex items-center gap-2 mb-2") do
        render Components::UserAvatar.new(
          user: comment.user,
          federails_actor: comment.federails_actor,
          name: comment.author_name,
          size: "h-7 w-7",
          fallback_class: "bg-surface-muted text-accent-text ring-1 ring-inset ring-border-muted font-bold"
        )
        span(class: "text-sm font-medium text-content-secondary truncate") { comment.author_name }
        if comment.author_host.present?
          span(class: "text-xs text-content-disabled shrink-0") { comment&.author_host }
        end
      end

      p(class: "text-sm text-content-muted mb-2 line-clamp-2") do
        plain truncate(comment.body, length: 80)
      end

      div(class: "flex items-center justify-between text-xs text-content-disabled") do
        span(class: "flex items-center gap-1") do
          Hero::Clock(variant: :outline, class: "w-3 h-3")
          plain "#{view_context.time_ago_in_words_korean(comment.created_at)} 전"
        end
        if comment.article.present?
          link_to(article_path(comment.article), class: "text-link hover:text-link-hover flex items-center gap-1 transition-colors") do
            Hero::ArrowTopRightOnSquare(variant: :outline, class: "w-3 h-3")
            plain "원문 보기"
          end
        end
      end
    end
  end
end
