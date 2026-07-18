# frozen_string_literal: true

require "test_helper"

class LayoutAssetPreconnectTest < ActiveSupport::TestCase
  def setup
    @layout = Components::Layout::AssetPreloads.allocate
    @original_asset_host = ActionController::Base.asset_host
  end

  def teardown
    ActionController::Base.asset_host = @original_asset_host
  end

  def request_for(host)
    Struct.new(:host).new(host)
  end

  test "람다형 asset_host는 request 호스트로 origin을 판별한다" do
    ActionController::Base.asset_host =
      ->(_source, request = nil) { request&.host == "ruby-news.jp" ? nil : "https://assets.ruby-news.dev" }

    assert_equal "https://assets.ruby-news.dev", @layout.send(:asset_preconnect_origin, request_for("ruby-news.dev"))
    assert_nil @layout.send(:asset_preconnect_origin, request_for("ruby-news.jp"))
  end

  test "문자열형 asset_host도 그대로 origin으로 반환한다" do
    ActionController::Base.asset_host = "https://cdn.example.com"

    assert_equal "https://cdn.example.com", @layout.send(:asset_preconnect_origin, request_for("ruby-news.dev"))
  end

  test "asset_host 미설정(개발환경)이면 nil이라 preconnect를 렌더하지 않는다" do
    ActionController::Base.asset_host = nil

    assert_nil @layout.send(:asset_preconnect_origin, request_for("ruby-news.dev"))
  end
end
