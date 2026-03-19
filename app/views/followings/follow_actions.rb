# frozen_string_literal: true

class Views::Followings::FollowActions < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(actor:)
    @actor = actor
  end

  def view_template
    current = Current.user
    policy = Federails::Client::FollowingPolicy.new(current, Federails::Following)

    div(id: "follow_actions_#{@actor.id}", class: "flex flex-wrap items-center gap-3 mt-2") do
      if policy.create?
        authenticated_actions(current)
      elsif current.nil?
        logged_out_message
      end
    end
  end

  private

  def authenticated_actions(current)
    follow = current.federails_actor.follows?(@actor)

    if @actor.entity == current
      span(class: "text-slate-400 text-sm") { "내 계정입니다." }
    elsif follow
      existing_follow(follow)
    else
      new_follow
    end

    incoming_follow_request(current)
  end

  def existing_follow(follow)
    if follow.pending?
      render RubyUI::Badge.new(variant: :amber) { "요청 중" }
    else
      render RubyUI::Badge.new(variant: :green) { "팔로잉" }
    end
    button_to follow.pending? ? "요청 취소" : "언팔로우",
      following_path(follow),
      method: :delete,
      class: "px-4 py-2 text-sm font-medium bg-slate-700 hover:bg-red-900 text-slate-300 hover:text-red-300 rounded-lg border border-slate-600 transition-colors cursor-pointer"
  end

  def new_follow
    button_to "팔로우",
      follow_followings_path,
      params: { account: @actor.at_address },
      method: :post,
      class: "px-4 py-2 text-sm font-medium bg-green-600 hover:bg-green-500 text-white rounded-lg transition-colors cursor-pointer"
  end

  def incoming_follow_request(current)
    followed = @actor.follows?(current.federails_actor)
    return unless followed

    if followed.pending?
      span(class: "text-slate-400 text-sm") { "#{@actor.username}이(가) 팔로우 요청했습니다." }
      button_to "수락",
        accept_following_path(followed),
        method: :put,
        class: "px-4 py-2 text-sm font-medium bg-blue-600 hover:bg-blue-500 text-white rounded-lg transition-colors cursor-pointer"
    else
      span(class: "text-slate-400 text-sm") { "#{@actor.username}이(가) 팔로우 중입니다." }
    end
  end

  def logged_out_message
    p(class: "text-slate-400 text-sm") do
      plain "팔로우하려면 로그인하세요. 또는 다른 Fediverse 서버에서 검색: "
      code(class: "ml-1 bg-slate-800 px-1.5 py-0.5 rounded text-slate-300 text-xs") do
        plain @actor.at_address(prefix: "")
      end
    end
  end
end
