# frozen_string_literal: true

class UserWorkspaceSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workspace

  def create
    upsert_subscription
  end

  def update
    upsert_subscription
  end

  def destroy
    subscription = current_user.user_workspace_subscriptions.find_by!(slack_workspace: @workspace)
    subscription.update!(active: false)

    redirect_to edit_user_registration_path, notice: "Slack 채널 구독을 비활성화했습니다."
  end

  def channels
    unless current_user.user_workspace_subscriptions.exists?(slack_workspace: @workspace)
      render json: { error: "접근 권한이 없습니다." }, status: :forbidden
      return
    end

    channels = Rails.cache.fetch("slack_channels/#{@workspace.id}", expires_in: 10.minutes) do
      SlackClient.new(@workspace).list_channels
    end
    render json: { channels: channels }
  rescue SlackClient::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_workspace
    @workspace = SlackWorkspace.find(params[:slack_workspace_id])
  end

  def upsert_subscription
    subscription = current_user.user_workspace_subscriptions.find_by(slack_workspace: @workspace)

    unless subscription
      redirect_to edit_user_registration_path, alert: "해당 워크스페이스에 연결되어 있지 않습니다."
      return
    end

    subscription.assign_attributes(subscription_params.merge(active: true))

    if subscription.save
      redirect_to edit_user_registration_path, notice: "Slack 채널 구독을 저장했습니다."
    else
      redirect_to edit_user_registration_path, alert: subscription.errors.full_messages.to_sentence
    end
  end

  def subscription_params
    params.expect(user_workspace_subscription: [ :channel_id, :channel_name ])
  end
end
