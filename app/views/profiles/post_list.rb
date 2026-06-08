# frozen_string_literal: true

class Views::Profiles::PostList < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(user:, posts:, pagy:, liked_post_ids: [], boosted_post_ids: [], drafts_count: 0, drafts: [], embedded: false)
    @user = user
    @posts = posts
    @pagy = pagy
    @liked_post_ids = liked_post_ids
    @boosted_post_ids = boosted_post_ids
    @drafts_count = drafts_count
    @drafts = drafts
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
    drafts = @drafts.to_a
    return if drafts.empty?

    div(class: "mb-4 rounded-lg border border-border-muted bg-surface p-4") do
      div(class: "flex items-center justify-between mb-3") do
        h2(class: "text-sm font-semibold text-content") { t("profiles.post_list.drafts_heading") }
        span(class: "text-xs text-content-muted") { t("profiles.post_list.drafts", count: drafts.size) }
      end
      div(class: "flex flex-col gap-2") do
        drafts.each { |draft| draft_row(draft) }
      end
    end
  end

  def draft_row(draft)
    div(class: "flex items-center justify-between gap-3 rounded-md border border-border-muted bg-app/40 px-3 py-2") do
      link_to(
        edit_longform_post_path(draft),
        class: "min-w-0 flex-1 truncate text-sm text-content hover:text-brand-text transition-colors"
      ) do
        plain draft.title.presence || t("posts.longform.untitled_draft")
      end
      div(class: "flex items-center gap-2 shrink-0") do
        link_to t("posts.longform.edit"), edit_longform_post_path(draft),
          class: "text-xs font-medium text-content-muted hover:text-content transition-colors"
        button_to t("posts.longform.delete"), longform_post_path(draft),
          method: :delete,
          form: { data: { turbo_confirm: t("posts.longform.delete_confirm") } },
          class: "text-xs font-medium text-content-muted hover:text-danger-text transition-colors cursor-pointer"
      end
    end
  end
end
