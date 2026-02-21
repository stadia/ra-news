# frozen_string_literal: true

class PushNotificationService < OperationService
  def call(user:, title:, body:, path:)
    return Failure(:web_push_not_configured) unless WebPushConfig.configured?

    payload = build_payload(title: title, body: body, path: path)
    step deliver_to_subscriptions(user:, payload:)
  end

  def notify_user(user:, title:, body:, path:)
    call(user:, title:, body:, path:)
  end

  private

  def deliver_to_subscriptions(user:, payload:)
    user.push_subscriptions.find_each do |subscription|
      step send_payload(subscription:, payload:)
    end

    Success(true)
  end

  def build_payload(title:, body:, path:)
    {
      title: title,
      options: {
        body: body,
        icon: "/icon.png",
        badge: "/icon.png",
        data: { path: path }
      }
    }.to_json
  end

  def send_payload(subscription:, payload:)
    WebPush.payload_send(
      message: payload,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh,
      auth: subscription.auth,
      vapid: {
        subject: WebPushConfig.subject,
        public_key: WebPushConfig.public_key,
        private_key: WebPushConfig.private_key,
        expiration: WebPushConfig.expiration_seconds
      }
    )

    subscription.update_columns(last_sent_at: Time.current, last_error_at: nil)
    Success(subscription)
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy!
    Success(subscription)
  rescue WebPush::Unauthorized => e
    if vapid_key_mismatch?(e)
      subscription.destroy!
      Success(subscription)
    else
      subscription.update_columns(last_error_at: Time.current)
      raise
    end
  rescue WebPush::ResponseError => e
    if subscription_expired?(e)
      subscription.destroy!
      Success(subscription)
    else
      subscription.update_columns(last_error_at: Time.current)
      raise
    end
  end

  def subscription_expired?(error)
    status_code = error.response&.code.to_i
    status_code == 404 || status_code == 410
  end

  def vapid_key_mismatch?(error)
    status_code = error.response&.code.to_i
    response_body = error.response&.body.to_s

    status_code == 401 && response_body.include?("VAPID public key mismatch")
  end
end
