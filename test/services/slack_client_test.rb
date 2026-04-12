# frozen_string_literal: true

require "test_helper"

class SlackClientTest < ActiveSupport::TestCase
  test "not_in_channel 이면 운영 가이드가 포함된 ApiError를 발생시킨다" do
    workspace = slack_workspaces(:acme)
    client = SlackClient.new(workspace)
    api_client = Struct.new(:calls) do
      def chat_postMessage(channel:, text:, blocks:)
        calls << [ :post, channel, text, blocks ]
        raise Slack::Web::Api::Errors::NotInChannel, "not_in_channel"
      end
    end.new([])

    error = assert_raises(SlackClient::ApiError) do
      client.stub(:client, api_client) do
        client.post_message(channel: "CPUBLIC1", text: "hello", blocks: [])
      end
    end

    assert_includes error.message, "Slack 봇이 채널에 참여하지 않아 메시지 전송에 실패했습니다."
    assert_includes error.message, "최소 권한 원칙"
    assert_includes error.message, "공개 채널과 비공개 채널 모두 Slack에서 앱을 해당 채널에 직접 초대"
    assert_includes error.message, "not_in_channel"
    assert_equal [ [ :post, "CPUBLIC1", "hello", [] ] ], api_client.calls
  end

  test "Faraday 오류를 ApiError로 래핑한다" do
    workspace = slack_workspaces(:acme)
    client = SlackClient.new(workspace)

    error = assert_raises(SlackClient::ApiError) do
      client.stub(:client, Struct.new(:exception) {
        def conversations_list(**)
          raise exception
        end
      }.new(Faraday::TimeoutError.new("execution expired"))) do
        client.list_channels
      end
    end

    assert_includes error.message, "execution expired"
  end
end
