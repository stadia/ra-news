# frozen_string_literal: true

class Views::Profiles::LongformList < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(user:, drafts: [], published: [], trash: [], embedded: false)
    @user = user
    @drafts = drafts
    @published = published
    @trash = trash
    @embedded = embedded
  end

  def view_template
    if @embedded
      list_content
    else
      content_for :title, "@#{@user.username} — #{t("profiles.activity_tabs.longform")}"
      div(class: "max-w-2xl mx-auto py-10 px-4 sm:px-6") do
        turbo_frame_tag("activity-list", class: "block") do
          render Components::Profiles::ActivityTabs.new(user: @user, active_tab: :longform)
          div(class: "mt-4") { list_content }
        end
      end
    end
  end

  private

  def list_content
    div(class: "flex flex-col gap-8") do
      drafts_section
      published_section
      trash_section
    end
  end

  def drafts_section
    section(class: "flex flex-col gap-3") do
      h2(class: "text-sm font-semibold text-content") { t("profiles.longform_list.drafts_heading") }
      drafts = @drafts.to_a
      if drafts.empty?
        empty_state(t("profiles.longform_list.drafts_empty"))
      else
        div(class: "flex flex-col gap-2") do
          drafts.each { |draft| draft_row(draft) }
        end
      end
    end
  end

  def published_section
    section(class: "flex flex-col gap-3") do
      h2(class: "text-sm font-semibold text-content") { t("profiles.longform_list.published_heading") }
      published = @published.to_a
      if published.empty?
        empty_state(t("profiles.longform_list.published_empty"))
      else
        div(class: "flex flex-col gap-2") do
          published.each { |post| published_row(post) }
        end
      end
    end
  end

  def trash_section
    section(class: "flex flex-col gap-3") do
      h2(class: "text-sm font-semibold text-content") { t("profiles.longform_list.trash_heading") }
      trash = @trash.to_a
      if trash.empty?
        empty_state(t("profiles.longform_list.trash_empty"))
      else
        div(class: "flex flex-col gap-2") do
          trash.each { |post| trash_row(post) }
        end
      end
    end
  end

  def empty_state(message)
    div(class: "text-center py-8 text-content-disabled") do
      p { message }
    end
  end

  # All controls render inside the "activity-list" turbo frame, so links/forms
  # use data-turbo-frame="_top" to navigate the whole page rather than
  # replacing the frame (which would otherwise show "Content missing").
  def draft_row(draft)
    row do
      link_to(
        edit_longform_post_path(draft),
        class: "min-w-0 flex-1 truncate text-sm text-content hover:text-brand-text transition-colors",
        data: { turbo_frame: "_top", turbo_prefetch: false }
      ) do
        plain draft.title.presence || t("posts.longform.untitled_draft")
      end
      div(class: "flex items-center gap-2 shrink-0") do
        button_to t("posts.longform.delete"), longform_post_path(draft),
          method: :delete,
          form: { data: { turbo_confirm: t("posts.longform.delete_confirm"), turbo_frame: "_top" } },
          class: "text-xs font-medium text-content-muted hover:text-danger-text transition-colors cursor-pointer"
      end
    end
  end

  def published_row(post)
    row do
      link_to(
        post_path(post),
        class: "min-w-0 flex-1 truncate text-sm text-content hover:text-brand-text transition-colors",
        data: { turbo_frame: "_top" }
      ) do
        plain post.title.presence || t("posts.longform.untitled_draft")
      end
      div(class: "flex items-center gap-2 shrink-0") do
        link_to t("posts.longform.edit"), edit_longform_post_path(post),
          class: "text-xs font-medium text-content-muted hover:text-content transition-colors",
          data: { turbo_frame: "_top", turbo_prefetch: false }
        button_to t("posts.longform.delete"), longform_post_path(post),
          method: :delete,
          form: { data: { turbo_confirm: t("posts.longform.delete_confirm"), turbo_frame: "_top" } },
          class: "text-xs font-medium text-content-muted hover:text-danger-text transition-colors cursor-pointer"
      end
    end
  end

  def trash_row(post)
    row do
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

  def row(&block)
    div(class: "flex items-center justify-between gap-3 rounded-md border border-border-muted bg-app/40 px-3 py-2", &block)
  end
end
