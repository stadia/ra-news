# frozen_string_literal: true

class Views::Activities::Feed < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(posts:, pagy:, liked_post_ids: [])
    @posts = posts
    @pagy = pagy
    @liked_post_ids = liked_post_ids
  end

  def view_template
    content_for :title, "피드 | Ruby-News"

    if @pagy.page == 1
      div(class: "max-w-2xl mx-auto") do
        render Components::Posts::PostForm.new
        posts_and_pagination
      end
    else
      turbo_frame_tag("feed_page_#{@pagy.page}", class: "block space-y-4") do
        posts_and_pagination
      end
    end
  end

  private

  def posts_and_pagination
    if @pagy.page == 1
      div(id: "posts_list", class: "space-y-4") do
        render_posts
        render_next_page_frame if @pagy.next
      end
    else
      render_posts
      render_next_page_frame if @pagy.next
    end
  end

  def render_posts
    if @posts.empty? && @pagy.page == 1
      render_empty_state
    else
      @posts.each do |post|
        render Components::Posts::PostCard.new(post: post, liked: @liked_post_ids.include?(post.id))
      end
    end
  end

  def render_empty_state
    render RubyUI::Card.new(class: "bg-surface border-border-muted shadow-sm") do
      render RubyUI::CardContent.new(class: "p-8 text-content-secondary text-center") do
        plain "표시할 포스트가 없습니다. 다른 사용자를 팔로우하거나 첫 포스트를 작성해보세요!"
      end
    end
  end

  def render_next_page_frame
    turbo_frame_tag(
      "feed_page_#{@pagy.next}",
      src: view_context.feed_path(page: @pagy.next),
      loading: :lazy,
      class: "block space-y-4",
      data: { controller: "infinite-scroll" }
    ) do
      div(class: "py-8 text-center text-content-muted") do
        plain "불러오는 중..."
      end
    end
  end
end
