# frozen_string_literal: true

require "test_helper"

# 화이트리스트 422 분기는 HTTP로는 도달하지 않는다 — 라우트의
# `defaults: { likeable_type: ... }`가 요청 파라미터를 덮어쓰기 때문이다.
# 그래서 이 불변식(지원 밖 타입 → nil)은 함수 단위로 고정한다.
class Reactions::TargetLookupTest < ActiveSupport::TestCase
  setup do
    @post = posts(:root_post)
    @article = articles(:ruby_article)
  end

  test "Post는 slug로 조회된다" do
    found = Reactions::TargetLookup.find(
      type: "Post",
      params: ActionController::Parameters.new(post_id: @post.to_param)
    )

    assert_equal @post, found
  end

  test "Article은 slug로 조회된다" do
    found = Reactions::TargetLookup.find(
      type: "Article",
      params: ActionController::Parameters.new(article_id: @article.to_param)
    )

    assert_equal @article, found
  end

  test "화이트리스트 밖 타입은 nil을 돌려준다" do
    assert_nil Reactions::TargetLookup.find(
      type: "Comment",
      params: ActionController::Parameters.new(comment_id: 1)
    )
  end

  test "nil 타입은 nil을 돌려준다" do
    assert_nil Reactions::TargetLookup.find(
      type: nil,
      params: ActionController::Parameters.new
    )
  end

  test "id 파라미터가 없으면 ParameterMissing을 올린다" do
    assert_raises(ActionController::ParameterMissing) do
      Reactions::TargetLookup.find(type: "Post", params: ActionController::Parameters.new)
    end
  end

  test "kept_only는 폐기된 대상을 제외한다" do
    @article.discard!

    assert_raises(ActiveRecord::RecordNotFound) do
      Reactions::TargetLookup.find(
        type: "Article",
        params: ActionController::Parameters.new(article_id: @article.to_param),
        kept_only: true
      )
    end
  end

  test "kept_only 없이는 폐기된 대상도 조회된다 — 좋아요 경로의 기존 동작" do
    @article.discard!

    found = Reactions::TargetLookup.find(
      type: "Article",
      params: ActionController::Parameters.new(article_id: @article.to_param)
    )

    assert_equal @article, found
  end
end
