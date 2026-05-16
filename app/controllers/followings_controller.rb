# frozen_string_literal: true
# rbs_inline: enabled

class FollowingsController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :set_following, only: [ :accept, :destroy ]
  after_action :verify_authorized, except: [ :new ]

  def new
    actor = Federails::Actor.find_or_create_by_federation_url(params.require(:uri))
    skip_authorization
    redirect_to actor_path(actor)
  end

  def create
    @following = build_following
    @following.actor = current_user.federails_actor
    authorize @following, policy_class: Federails::Client::FollowingPolicy

    persist_following(@following.target_actor)
  end

  def follow
    authorize Federails::Following, policy_class: Federails::Client::FollowingPolicy

    @following = build_following_from_account
    return render_follow_lookup_error unless @following

    persist_following(@following.target_actor)
  end

  def accept
    respond_with_accept(@following)
  end

  def destroy
    actor = @following.actor
    target_actor = @following.target_actor
    following = @following
    @following.destroy

    respond_with_destroy(actor:, target_actor:, following:)
  end

  private

  def set_following
    @following = Federails::Following.find_param(params[:id])
    authorize @following, policy_class: Federails::Client::FollowingPolicy
  end

  def following_params
    params.require(:following).permit(:target_actor_id)
  end

  def build_following
    Federails::Following.new(following_params)
  end

  def build_following_from_account
    Federails::Following.new_from_account(
      params.require(:account),
      actor: current_user.federails_actor
    )
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def persist_following(target_actor)
    respond_to do |format|
      if @following.save
        format.html { redirect_to actor_path(current_user.federails_actor), notice: "팔로우했습니다." }
        format.turbo_stream { render_follow_actions_stream(target_actor) }
        format.json { render json: { status: @following.status }, status: :created }
      else
        format.html { redirect_to actor_path(current_user.federails_actor), alert: "팔로우에 실패했습니다." }
        format.turbo_stream { render_follow_actions_stream(target_actor) }
        format.json { render json: @following.errors, status: :unprocessable_entity }
      end
    end
  end

  def render_follow_lookup_error
    respond_to do |format|
      format.html { redirect_to root_path, alert: "해당 계정을 찾을 수 없습니다." }
      format.turbo_stream { head :unprocessable_entity }
      format.json { render json: { target_actor: [ "does not exist" ] }, status: :unprocessable_entity }
    end
  end

  def respond_with_accept(following)
    follow_activity = following.follow_activity

    respond_to do |format|
      if follow_activity && following.accept!(follow_activity: follow_activity)
        format.html { redirect_to actor_path(following.actor), notice: "팔로우 요청을 수락했습니다." }
        format.turbo_stream { render_follow_actions_stream(following.actor, following:, remove_row: false) }
        format.json { render json: { status: following.status }, status: :ok }
      else
        format.html { redirect_to actor_path(following.actor), alert: "팔로우 요청 수락에 실패했습니다." }
        format.turbo_stream { render_follow_actions_stream(following.actor) }
        format.json { render json: following.errors, status: :unprocessable_entity }
      end
    end
  end

  def respond_with_destroy(actor:, target_actor:, following:)
    respond_to do |format|
      format.html { redirect_to actor_path(actor), notice: "팔로우를 취소했습니다." }
      format.turbo_stream { render_follow_actions_stream(target_actor, following:) }
      format.json { head :no_content }
    end
  end

  def render_follow_actions_stream(actor, following: nil, remove_row: true)
    streams = [ follow_actions_stream(actor) ]
    if following && (follow_list = follow_list_component_for(following))
      streams << turbo_stream.replace("follow-list", follow_list)
    end
    streams << turbo_stream.remove("following_row_#{following.id}") if following && remove_row
    render turbo_stream: streams
  end

  def follow_actions_stream(actor)
    turbo_stream.replace(
      Views::Followings::FollowActions.dom_id_for(actor),
      Views::Followings::FollowActions.new(actor: actor)
    )
  end

  def follow_list_component_for(following)
    if (user = following.target_actor.entity).is_a?(User)
      followings = following.target_actor.following_followers.to_a
      Views::Profiles::FollowList.new(user: user, followings: followings, type: :followers)
    elsif (user = following.actor.entity).is_a?(User)
      followings = following.actor.following_follows.to_a
      Views::Profiles::FollowList.new(user: user, followings: followings, type: :following)
    end
  end

  def pundit_user
    current_user
  end
end
