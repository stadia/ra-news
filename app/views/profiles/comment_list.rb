# frozen_string_literal: true

class Views::Profiles::CommentList < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(user:, posts:, pagy:, boosted_post_ids: [], embedded: false)
    @user = user
    @posts = posts
    @pagy = pagy
    @boosted_post_ids = boosted_post_ids
    @embedded = embedded
  end

  def view_template
    if @embedded
      list_content
    else
      content_for :title, "@#{@user.username} — #{t("profiles.activity_tabs.comments")}"
      div(class: "max-w-2xl mx-auto py-10 px-4 sm:px-6") do
        turbo_frame_tag("activity-list", class: "block") do
          render Components::Profiles::ActivityTabs.new(user: @user, active_tab: :comments)
          div(class: "mt-4") { list_content }
        end
      end
    end
  end

  private

  def list_content
    if @posts.empty?
      div(class: "text-center py-16 text-content-disabled") do
        p { t("profiles.comment_list.empty") }
      end
    else
      div(class: "flex flex-col gap-4") do
        div(class: "flex flex-col gap-3") do
          @posts.each do |post|
            render Components::Posts::PostCard.new(
              post: post,
              boosted: @boosted_post_ids.include?(post.id)
            )
          end
        end
        render Components::Pagination.new(pagy: @pagy)
      end
    end
  end
end
