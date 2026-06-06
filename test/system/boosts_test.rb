# frozen_string_literal: true

require "application_system_test_case"

class BoostsTest < ApplicationSystemTestCase
  setup do
    @user = users(:john)
    @article = articles(:ruby_article)
    login_as @user, scope: :user
  end

  test "boosting an article toggles the button via turbo and persists" do
    visit article_path(@article)

    frame = "#boost_article_#{@article.id}"
    assert_selector "#{frame} form", wait: 5
    assert_equal 0, @article.reload.boosters_count

    # 1) 부스트 — turbo_stream 으로 버튼이 교체되며 카운트 1 표시
    find("#{frame} button[type=submit]").click
    assert_selector frame, text: "1", wait: 5
    assert @user.boosts?(@article), "Boost row should be persisted after click"
    assert_equal 1, @article.reload.boosters_count

    take_screenshot

    # 2) 부스트 취소 — 카운트 사라지고 행 삭제
    find("#{frame} button[type=submit]").click
    assert_no_selector frame, text: "1", wait: 5
    assert_not @user.boosts?(@article), "Boost row should be removed after second click"
    assert_equal 0, @article.reload.boosters_count
  end
end
