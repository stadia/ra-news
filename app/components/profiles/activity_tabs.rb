# frozen_string_literal: true

class Components::Profiles::ActivityTabs < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(user:, active_tab:)
    @user = user
    @active_tab = active_tab
  end

  def view_template
    div(class: "flex justify-center") do
      render RubyUI::TabsList.new do
        tab_link(t("profiles.activity_tabs.posts"), user_profile_posts_path(username: @user.username), :posts)
        tab_link(t("profiles.activity_tabs.comments"), user_profile_comments_path(username: @user.username), :comments)
        tab_link(t("profiles.activity_tabs.followers"), user_profile_followers_path(username: @user.username), :followers) if own_profile?
        tab_link(t("profiles.activity_tabs.following"), user_profile_following_path(username: @user.username), :following) if own_profile?
        tab_link(t("profiles.activity_tabs.likes"), user_profile_likes_path(username: @user.username), :likes) if own_profile?
        tab_link(t("profiles.activity_tabs.boosts"), user_profile_boosts_path(username: @user.username), :boosts) if own_profile?
        tab_link(t("profiles.activity_tabs.longform"), user_profile_longform_path(username: @user.username), :longform) if own_profile?
      end
    end
  end

  private

  def tab_link(label, path, key)
    active = @active_tab == key
    classes = [
      "inline-flex items-center justify-center whitespace-nowrap rounded-md px-3 py-1 text-sm font-medium ring-offset-background transition-all",
      "data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
    ].join(" ")

    link_to(label, path,
      class: classes,
      data: {
        state: active ? "active" : "inactive",
        turbo_frame: "activity-list",
        turbo_action: "advance"
      })
  end

  def own_profile?
    view_context.current_user && view_context.current_user == @user
  end
end
