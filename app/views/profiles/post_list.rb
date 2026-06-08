# frozen_string_literal: true

class Views::Profiles::PostList < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(user:, posts:, pagy:, liked_post_ids: [], boosted_post_ids: [], drafts_count: 0, embedded: false)
    @user = user
    @posts = posts
    @pagy = pagy
    @liked_post_ids = liked_post_ids
    @boosted_post_ids = boosted_post_ids
    @drafts_count = drafts_count
    @embedded = embedded
  end

  def view_template
    if @embedded
      list_content
    else
      content_for :title, "@#{@user.username} — #{t("profiles.activity_tabs.posts")}"
      div(class: "max-w-2xl mx-auto py-10 px-4 sm:px-6") do
        turbo_frame_tag("activity-list", class: "block") do
          render Components::Profiles::ActivityTabs.new(user: @user, active_tab: :posts)
          div(class: "mt-4") { list_content }
        end
      end
    end
  end

  private

  def list_content
    draft_notice

    if @posts.empty?
      div(class: "text-center py-16 text-content-disabled") do
        p { t("profiles.post_list.empty") }
      end
    else
      div(class: "flex flex-col gap-4") do
        div(class: "flex flex-col gap-3") do
          @posts.each do |post|
            render Components::Posts::PostCard.new(
              post: post,
              liked: @liked_post_ids.include?(post.id),
              boosted: @boosted_post_ids.include?(post.id)
            )
          end
        end
        render Components::Pagination.new(pagy: @pagy)
      end
    end
  end

  def draft_notice
    return unless @drafts_count.to_i.positive?

    div(class: "mb-4 rounded-lg border border-border-muted bg-surface p-4 text-sm text-content-secondary") do
      plain t("profiles.post_list.drafts", count: @drafts_count)
    end
  end
end
