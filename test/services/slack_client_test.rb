# frozen_string_literal: true

require "test_helper"

class SlackClientTest < ActiveSupport::TestCase
  test "incoming webhook으로 메시지를 전송한다" do
    channel = notification_channels(:acme_slack)
    client = SlackClient.new(channel)
    response = Struct.new(:success?, :status).new(true, 200)
    webhook_client = Struct.new(:calls, :response) do
      def post
        request = Struct.new(:body).new
        yield request
        calls << request.body
        response
      end
    end.new([], response)

    client.stub(:webhook_client, webhook_client) do
      assert_equal({}, client.post_message(text: "hello", blocks: []))
    end

    assert_equal [ { text: "hello", blocks: [] } ], webhook_client.calls
  end

  test "Faraday 오류를 ApiError로 래핑한다" do
    channel = notification_channels(:acme_slack)
    client = SlackClient.new(channel)

    error = assert_raises(SlackClient::ApiError) do
      client.stub(:webhook_client, Struct.new(:exception) {
        def post
          raise exception
        end
      }.new(Faraday::TimeoutError.new("execution expired"))) do
        client.post_message(text: "hello", blocks: [])
      end
    end

    assert_includes error.message, "execution expired"
  end
end
