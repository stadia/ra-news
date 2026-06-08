# frozen_string_literal: true

class Views::Profiles::TrashList < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(user:, posts:, pagy:, embedded: false)
    @user = user
    @posts = posts
    @pagy = pagy
    @embedded = embedded
  end

  def view_template
    if @embedded
      list_content
    else
      content_for :title, "@#{@user.username} — #{t("profiles.activity_tabs.trash")}"
      div(class: "max-w-2xl mx-auto py-10 px-4 sm:px-6") do
        turbo_frame_tag("activity-list", class: "block") do
          render Components::Profiles::ActivityTabs.new(user: @user, active_tab: :trash)
          div(class: "mt-4") { list_content }
        end
      end
    end
  end

  private

  def list_content
    if @posts.empty?
      div(class: "text-center py-16 text-content-disabled") do
        p { t("profiles.trash_list.empty") }
      end
    else
      div(class: "flex flex-col gap-4") do
        h2(class: "text-sm font-semibold text-content") { t("profiles.trash_list.heading") }
        div(class: "flex flex-col gap-2") do
          @posts.each { |post| trash_row(post) }
        end
        render Components::Pagination.new(pagy: @pagy)
      end
    end
  end

  # This list renders inside the "activity-list" turbo frame. The controls
  # redirect to the trash page (a full page), so they navigate the whole page
  # with data-turbo-frame="_top" — matching how the draft list delete works.
  def trash_row(post)
    div(class: "flex items-center justify-between gap-3 rounded-md border border-border-muted bg-app/40 px-3 py-2") do
      span(class: "min-w-0 flex-1 truncate text-sm text-content") do
        plain post.title.presence || t("posts.longform.untitled_draft")
      end
      div(class: "flex items-center gap-2 shrink-0") do
        button_to t("posts.longform.restore"), undiscard_longform_post_path(post),
          method: :patch,
          form: { data: { turbo_frame: "_top" } },
          class: "text-xs font-medium text-content-muted hover:text-content transition-colors cursor-pointer"
        button_to t("posts.longform.destroy_permanently"), destroy_permanently_longform_post_path(post),
          method: :delete,
          form: { data: { turbo_confirm: t("posts.longform.destroy_permanently_confirm"), turbo_frame: "_top" } },
          class: "text-xs font-medium text-content-muted hover:text-danger-text transition-colors cursor-pointer"
      end
    end
  end
end
