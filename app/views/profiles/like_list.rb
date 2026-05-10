# frozen_string_literal: true

class Views::Profiles::LikeList < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(user:, likeables:, pagy:, embedded: false)
    @user = user
    @likeables = likeables
    @pagy = pagy
    @embedded = embedded
  end

  def view_template
    if @embedded
      list_content
    else
      content_for :title, "@#{@user.username} — 좋아요"
      div(class: "max-w-2xl mx-auto py-10 px-4 sm:px-6") do
        turbo_frame_tag("activity-list") { list_content }
      end
    end
  end

  private

  def list_content
    if @likeables.empty?
      div(class: "text-center py-16 text-content-disabled") do
        p { "아직 좋아요한 글이 없습니다." }
      end
    else
      div(class: "flex flex-col gap-4") do
        div(class: "flex flex-col gap-3") do
          @likeables.each { |item| render_likeable(item) }
        end
        render Components::Pagination.new(pagy: @pagy)
      end
    end
  end

  def render_likeable(item)
    case item
    when Article
      render Components::Articles::Article.new(article: item, liked: true)
    when Post
      render Components::Posts::PostCard.new(post: item, liked: true)
    end
  end
end
