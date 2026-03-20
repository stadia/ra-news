# frozen_string_literal: true

class FollowingsController < ApplicationController
  include Pundit::Authorization

  before_action :require_authentication
  before_action :set_following, only: [ :accept, :destroy ]
  after_action :verify_authorized, except: [ :new ]

  def new
    actor = Federails::Actor.find_or_create_by_federation_url(params.require(:uri))
    skip_authorization
    redirect_to actor_path(actor)
  end

  def create
    @following = Federails::Following.new(following_params)
    @following.actor = Current.user.federails_actor
    authorize @following, policy_class: Federails::Client::FollowingPolicy

    save_and_render(@following.target_actor)
  end

  def follow
    authorize Federails::Following, policy_class: Federails::Client::FollowingPolicy

    begin
      @following = Federails::Following.new_from_account(
        params.require(:account),
        actor: Current.user.federails_actor
      )
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to root_path, alert: "해당 계정을 찾을 수 없습니다." }
        format.turbo_stream { head :unprocessable_entity }
        format.json { render json: { target_actor: [ "does not exist" ] }, status: :unprocessable_entity }
      end
      return
    end

    save_and_render(@following.target_actor)
  end

  def accept
    following = @following
    respond_to do |format|
      if following.accept!
        format.html { redirect_to actor_path(following.actor), notice: "팔로우 요청을 수락했습니다." }
        format.turbo_stream { render_follow_actions_stream(following.actor, following: following) }
        format.json { render json: { status: following.status }, status: :ok }
      else
        format.html { redirect_to actor_path(following.actor), alert: "팔로우 요청 수락에 실패했습니다." }
        format.turbo_stream { render_follow_actions_stream(following.actor) }
        format.json { render json: following.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    actor = @following.actor
    target_actor = @following.target_actor
    following = @following
    @following.destroy

    respond_to do |format|
      format.html { redirect_to actor_path(actor), notice: "팔로우를 취소했습니다." }
      format.turbo_stream { render_follow_actions_stream(target_actor, following: following) }
      format.json { head :no_content }
    end
  end

  private

  def set_following
    @following = Federails::Following.find_param(params[:id])
    authorize @following, policy_class: Federails::Client::FollowingPolicy
  end

  def following_params
    params.require(:following).permit(:target_actor_id)
  end

  def save_and_render(target_actor)
    respond_to do |format|
      if @following.save
        format.html { redirect_to actor_path(Current.user.federails_actor), notice: "팔로우했습니다." }
        format.turbo_stream { render_follow_actions_stream(target_actor) }
        format.json { render json: { status: @following.status }, status: :created }
      else
        format.html { redirect_to actor_path(Current.user.federails_actor), alert: "팔로우에 실패했습니다." }
        format.turbo_stream { render_follow_actions_stream(target_actor) }
        format.json { render json: @following.errors, status: :unprocessable_entity }
      end
    end
  end

  def render_follow_actions_stream(actor, following: nil)
    streams = [
      turbo_stream.replace(
        "follow_actions_#{actor.id}",
        Views::Followings::FollowActions.new(actor: actor)
      )
    ]
    streams << turbo_stream.remove("following_row_#{following.id}") if following
    render turbo_stream: streams
  end

  def pundit_user
    Current.user
  end
end
