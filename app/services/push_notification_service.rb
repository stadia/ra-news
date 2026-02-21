# frozen_string_literal: true

class PushNotificationService
  #: (User user, String title, String body, String path) -> void
  def notify_user(user:, title:, body:, path:)
    return unless WebPushConfig.configured?

    payload = build_payload(title: title, body: body, path: path)

    user.push_subscriptions.find_each do |subscription|
      send_payload(subscription: subscription, payload: payload)
    end
  end

  private

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
        expiration: 12.hours.from_now.to_i
      }
    )

    subscription.update_columns(last_sent_at: Time.current, last_error_at: nil)
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy!
  rescue WebPush::ResponseError => e
    if subscription_expired?(e)
      subscription.destroy!
    else
      subscription.update_columns(last_error_at: Time.current)
      raise
    end
  end

  def subscription_expired?(error)
    status_code = error.response&.code.to_i
    status_code == 404 || status_code == 410
  end
end
