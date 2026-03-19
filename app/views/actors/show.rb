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
    render RubyUI::Card.new(class: "bg-slate-900/40 border-slate-800 rounded-2xl overflow-hidden shadow-2xl") do
      div(class: "h-24 bg-linear-to-r from-green-900/30 to-slate-800/50 border-b border-slate-800")

      render RubyUI::CardContent.new(class: "px-6 pb-8 sm:px-10 sm:pb-10") do
        div(class: "flex flex-col sm:flex-row items-center sm:items-end gap-6 -mt-12 mb-8") do
          render RubyUI::Avatar.new(size: :xl, class: "h-24 w-24 ring-4 ring-slate-900 bg-slate-900 shadow-xl") do
            render RubyUI::AvatarFallback.new(class: "bg-slate-600 text-white text-3xl font-bold") do
              plain initials
            end
          end

          div(class: "text-center sm:text-left pb-1") do
            h1(class: "text-3xl font-bold text-white tracking-tight") { @actor.name }
            p(class: "text-slate-400 font-mono text-sm mt-1") { @actor.at_address }

            div(class: "flex items-center gap-4 mt-2") do
              span(class: "text-sm text-slate-400") do
                span(class: "font-semibold text-white") { @actor.following_followers.size.to_s }
                plain " 팔로워"
              end
              span(class: "text-sm text-slate-400") do
                span(class: "font-semibold text-white") { @actor.following_follows.size.to_s }
                plain " 팔로잉"
              end
            end
          end
        end

        render RubyUI::CardFooter.new(class: "px-0 pt-6 pb-0 border-t border-slate-800/60") do
          div(class: "flex flex-col sm:flex-row sm:items-center gap-4") do
            render Views::Followings::FollowActions.new(actor: @actor)

            if @actor.local?
              link_to "활동 보기", actor_activities_path(@actor),
                class: "text-sm text-slate-400 hover:text-white transition-colors"
            elsif @actor.profile_url
              link_to "프로필 방문 →", @actor.profile_url,
                class: "text-sm text-slate-400 hover:text-white transition-colors",
                target: "_blank", rel: "noopener noreferrer"
            end
          end
        end
      end
    end
  end

  def initials
    (@actor.name.presence || @actor.username.presence || "?").first.upcase
  end
end
