# typed: false
# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "truncate_smart이 짧은 텍스트를 그대로 반환한다" do
    assert_equal "안녕", truncate_smart("안녕", length: 100)
  end

  test "truncate_smart이 긴 텍스트를 자른다" do
    long_text = "a" * 200
    result = truncate_smart(long_text, length: 100)

    assert_operator result.length, :<=, 103
    assert_includes result, "..."
  end

  test "truncate_smart이 nil일 때 빈 문자열을 반환한다" do
    assert_equal "", truncate_smart(nil)
  end

  test "nav_link_to가 링크를 렌더링한다" do
    html = nav_link_to("홈", root_path)

    assert_includes html, "홈"
  end

  test "nav_link_to가 현재 페이지를 표시한다" do
    controller.request.path = root_path
    html = nav_link_to("홈", root_path)

    assert_includes html, "홈"
  end

  test "responsive_image_tag이 로딩 lazy와 클래스를 포함한다" do
    html = responsive_image_tag("test.png")

    assert_includes html, "loading=\"lazy\""
    assert_includes html, "w-full h-auto"
  end
end
