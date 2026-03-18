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
      h3(class: "text-lg font-semibold text-gray-100 mb-4 flex items-center gap-2") do
        Hero::ChatBubbleLeftRight(variant: :outline, class: "w-5 h-5 text-green-400")
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
    render RubyUI::Card.new(class: "bg-gray-800 p-3 border-gray-700 hover:border-gray-600 transition-colors rounded-lg") do
      div(class: "flex items-center gap-2 mb-2") do
        render RubyUI::Avatar.new(size: :sm, class: "shrink-0") do
          render RubyUI::AvatarFallback.new(class: "bg-linear-to-r from-blue-500 to-purple-600 text-white font-bold") do
            plain comment.author_name.to_s.first.to_s.upcase
          end
        end
        span(class: "text-sm font-medium text-gray-300 truncate") { comment.author_name }
        if comment.guest? || comment.federated_url.present?
          span(class: "text-xs text-gray-500 shrink-0") { comment&.author_host }
        end
      end

      p(class: "text-sm text-gray-400 mb-2 line-clamp-2") do
        plain truncate(comment.body, length: 80)
      end

      div(class: "flex items-center justify-between text-xs text-gray-500") do
        span(class: "flex items-center gap-1") do
          Hero::Clock(variant: :outline, class: "w-3 h-3")
          plain "#{view_context.time_ago_in_words_korean(comment.created_at)} 전"
        end
        if comment.article.present?
          link_to(article_path(comment.article), class: "text-green-400 hover:text-green-300 flex items-center gap-1 transition-colors") do
            Hero::ArrowTopRightOnSquare(variant: :outline, class: "w-3 h-3")
            plain "원문 보기"
          end
        end
      end
    end
  end
end
