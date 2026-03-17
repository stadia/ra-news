# frozen_string_literal: true

class Views::Profiles::FollowList < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::TurboFrameTag
  include PhlexIcons

  def initialize(user:, actors:, type:, embedded: false)
    @user = user
    @actors = actors
    @type = type
    @embedded = embedded
  end

  def view_template
    title = @type == :followers ? "팔로워" : "팔로잉"

    if @embedded
      list_content(title)
    else
      content_for :title, "@#{@user.username} — #{title}"
      div(class: "max-w-2xl mx-auto py-10 px-4 sm:px-6") do
        turbo_frame_tag("follow-list") do
          list_content(title)
        end
      end
    end
  end

  private

  def list_content(title)
    if @actors.empty?
      div(class: "text-center py-16 text-slate-500") do
        p { @type == :followers ? "아직 팔로워가 없습니다." : "아직 팔로잉하는 계정이 없습니다." }
      end
    else
      div(class: "flex flex-col gap-2") do
        @actors.each { |actor| actor_row(actor) }
      end
    end
  end

  def actor_row(actor)
    site_host = URI.parse(Federails.configuration.site_host).host
    is_local = actor.server.blank? || actor.server == site_host
    handle = is_local ? "@#{actor.username}" : "@#{actor.username}@#{actor.server}"

    div(class: "flex items-center gap-4 px-4 py-3 bg-slate-900/40 border border-slate-800 rounded-xl hover:border-slate-700 transition-colors") do
      render RubyUI::Avatar.new(size: :md, class: "h-10 w-10 flex-shrink-0") do
        render RubyUI::AvatarFallback.new(class: "bg-green-700 text-white font-bold") do
          plain (actor.name.presence || actor.username).first.upcase
        end
      end

      div(class: "flex-1 min-w-0") do
        if is_local && (local_user = actor.entity)
          a(href: "/@#{local_user.username}", class: "text-white font-semibold hover:text-green-400 transition-colors block truncate") do
            plain actor.name.presence || actor.username
          end
        else
          p(class: "text-white font-semibold truncate") { actor.name.presence || actor.username }
        end
        p(class: "text-slate-400 text-sm font-mono truncate") { handle }
      end
    end
  end
end
