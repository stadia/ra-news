# frozen_string_literal: true

class Views::Posts::Show < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  def initialize(posts:, liked_post_ids: [])
    @posts = posts
    @liked_post_ids = liked_post_ids
  end

  def view_template
    content_for :title, "포스트 | Ruby-News"

    div(class: "max-w-2xl mx-auto space-y-4") do
      back_link
      render_posts
    end
  end

  private

  def back_link
    div(class: "mb-2") do
      link_to feed_path, class: "inline-flex items-center gap-1.5 text-sm text-content-muted hover:text-content transition-colors" do
        Hero::ArrowLeft(variant: :outline, class: "w-4 h-4")
        plain "피드로 돌아가기"
      end
    end
  end

  def render_posts
    root = @posts.first
    return unless root

    # 루트 포스트
    render Components::Posts::PostCard.new(
      post: root,
      liked: @liked_post_ids.include?(root.id)
    )

    # 답글 영역
    replies = @posts[1..] || []
    div(id: "replies_#{root.id}", class: "space-y-4") do
      replies.sort_by(&:created_at).each do |reply|
        render Components::Posts::PostCard.new(
          post: reply,
          liked: @liked_post_ids.include?(reply.id)
        )
      end
    end
  end
end
