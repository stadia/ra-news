# frozen_string_literal: true

require "test_helper"

class PushNotificationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @subscription = push_subscriptions(:john_browser)
    @service = PushNotificationService.new
  end

  test "설정이 존재하면 WebPush로 발송한다" do
    payload_sent = false
    push_stub = proc do |**kwargs|
      payload_sent = true

      assert_equal @subscription.endpoint, kwargs[:endpoint]
      assert_equal @subscription.p256dh, kwargs[:p256dh]
      assert_equal @subscription.auth, kwargs[:auth]
    end

    WebPushConfig.stub(:configured?, true) do
      WebPushConfig.stub(:subject, "mailto:admin@example.com") do
        WebPushConfig.stub(:public_key, "public") do
          WebPushConfig.stub(:private_key, "private") do
            WebPush.stub(:payload_send, push_stub) do
              @service.notify_user(user: @user, title: "title", body: "body", path: "/articles/test")
            end
          end
        end
      end
    end

    assert payload_sent
    assert_not_nil @subscription.reload.last_sent_at
  end

  test "설정이 없으면 발송하지 않는다" do
    assert_nothing_raised do
      WebPushConfig.stub(:configured?, false) do
        WebPush.stub(:payload_send, ->(**_kwargs) { raise "should not be called" }) do
          @service.notify_user(user: @user, title: "title", body: "body", path: "/articles/test")
        end
      end
    end
  end

  test "410 응답이면 구독을 삭제한다" do
    response = Struct.new(:code, :body).new("410", "expired")
    error = WebPush::ResponseError.new(response, "example.com")

    WebPushConfig.stub(:configured?, true) do
      WebPushConfig.stub(:subject, "mailto:admin@example.com") do
        WebPushConfig.stub(:public_key, "public") do
          WebPushConfig.stub(:private_key, "private") do
            WebPush.stub(:payload_send, ->(**_kwargs) { raise error }) do
              @service.notify_user(user: @user, title: "title", body: "body", path: "/articles/test")
            end
          end
        end
      end
    end

    assert_not PushSubscription.exists?(@subscription.id)
  end
end
