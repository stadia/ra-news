# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class PushSubscriptionsController < ApplicationController
  def create
    return head :unauthorized if current_user.nil?

    subscription = current_user.push_subscriptions.find_or_initialize_by(endpoint: subscription_params[:endpoint])
    subscription.assign_attributes(subscription_params.except(:endpoint))

    if subscription.save
      head :ok
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    return head :unauthorized if current_user.nil?

    endpoint = params[:endpoint].presence || params.dig(:push_subscription, :endpoint)
    return head :bad_request if endpoint.blank?

    current_user.push_subscriptions.where(endpoint: endpoint).destroy_all
    head :no_content
  end

  private

  def subscription_params
    params.expect(push_subscription: [ :endpoint, :p256dh, :auth, :expiration_time ])
  end
end
