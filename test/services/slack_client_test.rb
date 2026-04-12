# frozen_string_literal: true

require "test_helper"

class SlackClientTest < ActiveSupport::TestCase
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
