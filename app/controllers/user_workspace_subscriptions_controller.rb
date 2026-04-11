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
    channels = SlackClient.new(@workspace).list_channels
    render json: { channels: channels }
  rescue SlackClient::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_workspace
    @workspace = SlackWorkspace.find(params[:slack_workspace_id])
  end

  def upsert_subscription
    subscription = current_user.user_workspace_subscriptions.find_or_initialize_by(slack_workspace: @workspace)
    subscription.assign_attributes(subscription_params.merge(active: true))

    if subscription.save
      redirect_to edit_user_registration_path, notice: "Slack 채널 구독을 저장했습니다."
    else
      redirect_to edit_user_registration_path, alert: subscription.errors.full_messages.to_sentence
    end
  end

  def subscription_params
    params.expect(user_workspace_subscription: [ :slack_user_id, :channel_id, :channel_name ])
  end
end
