# typed: true
# app/views/actors/show.rb
# frozen_string_literal: true

class Views::Actors::Show < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  def initialize(actor:)
    @actor = actor
  end

  def view_template
    content_for :title, @actor.name

    div(class: "max-w-2xl mx-auto py-12 px-4 sm:px-6") do
      profile_card
    end
  end

  private

  def profile_card
    render RubyUI::Card.new(class: "bg-app/40 border-border-subtle rounded-2xl overflow-hidden shadow-2xl") do
      div(class: "h-24 bg-linear-to-r from-brand-strong/30 to-surface/50 border-b border-border-subtle")

      render RubyUI::CardContent.new(class: "px-6 pb-8 sm:px-10 sm:pb-10") do
        div(class: "flex flex-col sm:flex-row items-center sm:items-end gap-6 -mt-12 mb-8") do
          render RubyUI::Avatar.new(size: :xl, class: "h-24 w-24 ring-4 ring-app bg-app shadow-xl") do
            if avatar_url
              render RubyUI::AvatarImage.new(src: avatar_url, alt: @actor.name)
            else
              render RubyUI::AvatarFallback.new(class: "bg-brand-solid text-brand-foreground text-3xl font-bold") do
                plain initials
              end
            end
          end

          div(class: "text-center sm:text-left pb-1") do
            h1(class: "text-3xl font-bold text-content tracking-tight") { @actor.name }
            p(class: "text-content-muted font-mono text-sm mt-1") { @actor.at_address }

            if @actor.profile_url && !@actor.local?
              link_to t("actors.show.visit_profile"), @actor.profile_url,
                class: "text-sm text-content-muted hover:text-content transition-colors mt-1 inline-block",
                target: "_blank", rel: "noopener noreferrer"
            end

            div do
              link_to t("actors.show.back_to_lookup"), lookup_actors_path,
                class: "text-sm text-content-muted hover:text-content transition-colors mt-1 inline-block"
            end

            div(class: "flex items-center gap-4 mt-2") do
              span(class: "text-sm text-content-muted") do
                span(class: "font-semibold text-content") { @actor.following_followers.count.to_s }
                plain t("profiles.show.followers_suffix")
              end
              span(class: "text-sm text-content-muted") do
                span(class: "font-semibold text-content") { @actor.following_follows.count.to_s }
                plain t("profiles.show.following_suffix")
              end
            end
          end
        end

        render RubyUI::CardFooter.new(class: "px-0 pt-6 pb-0 border-t border-border-subtle/60") do
          div(class: "flex flex-col sm:flex-row sm:items-center gap-4") do
            render Views::Followings::FollowActions.new(actor: @actor)
          end
        end
      end
    end
  end

  def initials
    (@actor.name.presence || @actor.username.presence || "?").first.upcase
  end

  def avatar_url
    if @actor.local? && @actor.entity.respond_to?(:avatar_url) && @actor.entity.avatar_attached?
      @actor.entity.avatar_url
    else
      @actor.extensions&.dig("icon", "url")
    end
  end
end
