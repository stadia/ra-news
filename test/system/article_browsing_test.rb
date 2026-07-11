# frozen_string_literal: true

require "application_system_test_case"

class ArticleBrowsingTest < ApplicationSystemTestCase
  setup do
    @article = articles(:ruby_article)
  end

  # articles#index/#show 는 authenticate_user! 를 skip 하므로 비로그인으로도 성립하는
  # 순수 조회 스모크. 목록에서 기사 카드를 클릭해 상세로 이동, 제목/본문 노출을 확인한다.
  test "비로그인 사용자가 목록에서 기사를 열어 상세를 조회한다" do
    visit articles_path

    # 기사 카드는 link_to article.display_title, article_path(article) 로 렌더된다.
    assert_text @article.display_title
    click_link @article.display_title, match: :first

    # 상세 페이지: h1 에 display_title, 본문 영역에 body 가 노출된다.
    assert_current_path article_path(@article)
    assert_text @article.display_title
    assert_text I18n.t("comments.comment_form.title")
  end
end
