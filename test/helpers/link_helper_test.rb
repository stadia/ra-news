# typed: false
# frozen_string_literal: true

require "test_helper"

class LinkHelperTest < ActionView::TestCase
  include LinkHelper

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
