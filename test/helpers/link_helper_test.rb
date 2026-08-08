# frozen_string_literal: true

require "test_helper"

class LinkHelperTest < ActionView::TestCase
  include LinkHelper

  test "invalid_uri?는 경로가 없는 URI를 거부한다" do
    assert invalid_uri?(URI.parse("mailto:foo@example.com"))
  end

  test "invalid_uri?는 기사 경로가 있는 URI를 허용한다" do
    assert_not invalid_uri?(URI.parse("https://example.com/articles/1"))
  end

  test "youtube_id가 watch 쿼리 파라미터를 추출한다" do
    assert_equal "abc123", youtube_id("https://www.youtube.com/watch?v=abc123")
  end

  test "youtube_id가 /live 경로를 추출한다" do
    assert_equal "xyz789", youtube_id("https://www.youtube.com/live/xyz789")
  end

  test "youtube_id가 mailto URL에서 nil을 반환한다" do
    # URI.parse("mailto:...").path는 nil — 가드절이 없었다면 NoMethodError였을 경로
    assert_nil youtube_id("mailto:foo@example.com")
  end

  test "youtube_id가 nil 입력에서 nil을 반환한다" do
    assert_nil youtube_id(nil)
  end
end
