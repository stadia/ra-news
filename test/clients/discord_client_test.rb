# frozen_string_literal: true

require "test_helper"

class DiscordClientTest < ActiveSupport::TestCase
  test "post_embed는 Discord webhook으로 embed를 전송하고 message id를 반환한다" do
    channel = notification_channels(:acme_discord)
    client = DiscordClient.new(channel)

    response_body = { "id" => "msg-123", "content" => "" }.to_json
    fake_response = Struct.new(:body).new(response_body)

    fake_webhook = Struct.new(:response) do
      def execute(_builder, _wait, &block)
        response
      end
    end.new(fake_response)

    Discordrb::Webhooks::Client.stub(:new, fake_webhook) do
      result = client.post_embed(title: "Test", url: "https://example.com", description: "desc", color: 3447003)

      assert_equal "msg-123", result
    end
  end

  test "post_embed는 RestClient 오류를 ApiError로 래핑한다" do
    channel = notification_channels(:acme_discord)
    client = DiscordClient.new(channel)

    fake_webhook = Struct.new(:exception) do
      def execute(*, &)
        raise exception
      end
    end.new(RestClient::Forbidden.new)

    error = assert_raises(DiscordClient::ApiError) do
      Discordrb::Webhooks::Client.stub(:new, fake_webhook) do
        client.post_embed(title: "Test", url: "https://example.com")
      end
    end

    assert_includes error.message, "RestClient::Forbidden"
  end

  test "authorize_url은 Discord OAuth URL을 생성한다" do
    DiscordConfig.stub(:client_id, "dc-123") do
      url = DiscordClient.authorize_url(redirect_uri: "https://example.com/callback", state: "abc")

      assert_includes url, "discord.com/api/oauth2/authorize"
      assert_includes url, "client_id=dc-123"
      assert_includes url, "state=abc"
      assert_includes url, "scope=bot+webhook.incoming"
    end
  end

  test "exchange_code는 Faraday 오류를 ApiError로 래핑한다" do
    faraday_error = Faraday::ConnectionFailed.new("connection refused")

    DiscordConfig.stub(:client_id, "dc-123") do
      DiscordConfig.stub(:client_secret, "secret") do
        Faraday.stub(:post, ->(*) { raise faraday_error }) do
          error = assert_raises(DiscordClient::ApiError) do
            DiscordClient.exchange_code("bad-code", redirect_uri: "https://example.com/callback")
          end

          assert_includes error.message, "connection refused"
        end
      end
    end
  end

  test "Faraday 요청에 timeout을 설정한다" do
    timeout_values = []
    response = Struct.new(:success?, :status, :body).new(true, 200, { "guild" => { "id" => "G1" } }.to_json)

    request_factory = lambda do
      options = Struct.new(:open_timeout, :timeout).new
      Struct.new(:headers, :body, :options).new({}, nil, options)
    end

    DiscordConfig.stub(:client_id, "dc-123") do
      DiscordConfig.stub(:client_secret, "secret") do
        Faraday.stub(:post, lambda { |url, &block|
          req = request_factory.call
          block.call(req)
          timeout_values << [ url, req.options.open_timeout, req.options.timeout ]
          response
        }) do
          DiscordClient.exchange_code("good-code", redirect_uri: "https://example.com/callback")
        end
      end
    end

    Faraday.stub(:get, lambda { |url, &block|
      req = request_factory.call
      block.call(req)
      timeout_values << [ url, req.options.open_timeout, req.options.timeout ]
      Struct.new(:success?, :status, :body).new(true, 200, [ { "id" => "1", "type" => 0 } ].to_json)
    }) do
      DiscordClient.list_channels("bot-token", "guild-1")
    end

    Faraday.stub(:post, lambda { |url, &block|
      req = request_factory.call
      block.call(req)
      timeout_values << [ url, req.options.open_timeout, req.options.timeout ]
      Struct.new(:success?, :status, :body).new(true, 200, { id: "WH1", token: "token" }.to_json)
    }) do
      DiscordClient.create_webhook("bot-token", "channel-1")
    end

    assert_equal [
      [ DiscordClient::TOKEN_URL, 5, 10 ],
      [ "#{DiscordClient::API_BASE}/guilds/guild-1/channels", 5, 10 ],
      [ "#{DiscordClient::API_BASE}/channels/channel-1/webhooks", 5, 10 ]
    ], timeout_values
  end
end
