# frozen_string_literal: true

class Views::Profiles::Show < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::Tag
  include Phlex::Rails::Helpers::TurboFrameTag
  include PhlexIcons

  def initialize(user:, actor:, followers_count: 0, following_count: 0, follow_actors: nil, follow_type: nil)
    @user = user
    @actor = actor
    @followers_count = followers_count
    @following_count = following_count
    @follow_actors = follow_actors
    @follow_type = follow_type
  end

  def view_template
    content_for :title, "@#{@user.username} — #{@user.name}"

    if @actor
      site_host = URI.parse(Federails.configuration.site_host).host
      content_for :head, tag.meta(name: "fediverse:creator", content: "@#{@user.username}@#{site_host}")
    end

    div(class: "max-w-2xl mx-auto py-12 px-4 sm:px-6") do
      profile_card
      fediverse_section if @actor
      turbo_frame_tag("follow-list", class: "mt-2 block") do
        if @follow_actors
          render Views::Profiles::FollowList.new(user: @user, followings: @follow_actors, type: @follow_type, embedded: true)
        end
      end
    end
  end

  private

  def profile_card
    render RubyUI::Card.new(class: "bg-app/40 border-border-subtle rounded-2xl overflow-hidden shadow-2xl") do
      div(class: "h-24 bg-linear-to-r from-brand-strong/30 to-surface/50 border-b border-border-subtle")

      render RubyUI::CardContent.new(class: "px-6 pb-8 sm:px-10 sm:pb-10") do
        div(class: "flex flex-col sm:flex-row items-center sm:items-end gap-6 -mt-12 mb-8") do
          render RubyUI::Avatar.new(size: :xl, class: "h-24 w-24 ring-4 ring-app bg-app shadow-xl") do
            if @user.avatar_attached?
              render RubyUI::AvatarImage.new(src: @user.avatar_url, alt: @user.name)
            else
              render RubyUI::AvatarFallback.new(class: "bg-brand-solid text-brand-foreground text-3xl font-bold") do
                plain initials
              end
            end
          end

          div(class: "text-center sm:text-left pb-1") do
            h1(class: "text-3xl font-bold text-content tracking-tight") { @user.name }
            p(class: "text-content-muted font-mono text-sm mt-1") { "@#{@user.username}" }
            if own_profile?
              div(class: "flex items-center gap-3 mt-2") do
                link_to "설정", edit_user_registration_path,
                  class: "inline-flex items-center gap-1 mt-2 text-sm text-content-muted hover:text-content transition-colors"
                span(class: "text-content-disabled") { "·" }
                link_to "Feed", feed_path,
                  class: "inline-flex items-center gap-1 mt-2 text-sm text-content-muted hover:text-content transition-colors"
                span(class: "text-content-disabled") { "·" }
                link_to "팔로우 검색", lookup_actors_path,
                  class: "inline-flex items-center gap-1 mt-2 text-sm text-content-muted hover:text-content transition-colors"
              end
            end
            div(class: "flex items-center gap-4 mt-2") do
              link_to(
                "/@#{@user.username}/followers",
                class: "text-sm text-content-muted hover:text-content transition-colors",
                data: { turbo_frame: "follow-list", turbo_action: "advance" }
              ) do
                span(class: "font-semibold text-content") { @followers_count.to_s }
                plain " 팔로워"
              end
              link_to(
                "/@#{@user.username}/following",
                class: "text-sm text-content-muted hover:text-content transition-colors",
                data: { turbo_frame: "follow-list", turbo_action: "advance" }
              ) do
                span(class: "font-semibold text-content") { @following_count.to_s }
                plain " 팔로잉"
              end
            end
          end
        end

        if @actor
          render RubyUI::CardFooter.new(class: "px-0 pt-6 pb-0 border-t border-border-subtle/60") do
            fediverse_badge
          end
        end
      end
    end
  end

  def fediverse_badge
    site_host = URI.parse(Federails.configuration.site_host).host
    handle = "@#{@user.username}@#{site_host}"

    div(class: "flex flex-col sm:flex-row sm:items-center gap-3") do
      div(class: "flex items-center gap-2 text-content-muted") do
        svg(
          class: "w-5 h-5 shrink-0",
          fill: "currentColor",
          viewBox: "0 0 24 24",
          xmlns: "http://www.w3.org/2000/svg"
        ) do |s|
          s.path(
            d: "M23.268 5.313c-.35-2.578-2.617-4.61-5.304-5.004C17.51.242 15.792 0 11.813 0h-.03c-3.98 0-4.835.242-5.288.309C3.882.692 1.496 2.518.917 5.127.64 6.412.61 7.837.661 9.143c.074 1.874.088 3.745.26 5.611.118 1.24.325 2.47.62 3.68.55 2.237 2.777 4.098 4.96 4.857 2.336.792 4.849.923 7.256.38.265-.061.527-.132.786-.213.585-.184 1.27-.39 1.774-.753a.057.057 0 0 0 .023-.043v-1.809a.052.052 0 0 0-.02-.041.053.053 0 0 0-.046-.01 20.282 20.282 0 0 1-4.709.545c-2.73 0-3.463-1.284-3.674-1.818a5.593 5.593 0 0 1-.319-1.433.056.056 0 0 1 .017-.043.051.051 0 0 1 .043-.017c1.513.359 3.072.538 4.657.546 1.828 0 2.298-.081 3.09-.143 1.897-.149 3.566-.867 3.772-1.531.334-1.076.61-3.495.61-3.495 0-.732-.005-1.603-.05-2.447-.041-.832-.126-1.62-.333-2.377z"
          )
        end
        span(class: "font-mono text-sm text-content-secondary") { handle }
      end
    end
  end

  def fediverse_section
    nil
  end

  def own_profile?
    view_context.current_user && view_context.current_user == @user
  end

  def initials
    (@user.name.presence || @user.username.presence || "?").first.upcase
  end
end
