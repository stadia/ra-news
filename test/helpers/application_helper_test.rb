# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "time_ago_in_words_korean이 방금을 반환한다" do
    assert_equal "방금", time_ago_in_words_korean(Time.current)
    assert_equal "방금", time_ago_in_words_korean(30.seconds.ago)
  end

  test "time_ago_in_words_korean이 분을 반환한다" do
    assert_equal "5분", time_ago_in_words_korean(5.minutes.ago)
    assert_equal "59분", time_ago_in_words_korean(59.minutes.ago)
  end

  test "time_ago_in_words_korean이 시간을 반환한다" do
    assert_equal "1시간", time_ago_in_words_korean(1.hour.ago)
    assert_equal "23시간", time_ago_in_words_korean(23.hours.ago)
  end

  test "time_ago_in_words_korean이 일과 시간 경계를 반환한다" do
    assert_equal "1일", time_ago_in_words_korean(1.day.ago)
    assert_equal "29일", time_ago_in_words_korean(29.days.ago)
  end

  test "time_ago_in_words_korean이 개월을 반환한다" do
    assert_equal "1개월", time_ago_in_words_korean(1.month.ago)
  end

  test "time_ago_in_words_korean이 년을 반환한다" do
    assert_equal "1년", time_ago_in_words_korean(1.year.ago)
    assert_equal "2년", time_ago_in_words_korean(2.years.ago)
  end

  test "time_ago_in_words_korean이 nil일 때 알 수 없음을 반환한다" do
    assert_equal "알 수 없음", time_ago_in_words_korean(nil)
  end

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
