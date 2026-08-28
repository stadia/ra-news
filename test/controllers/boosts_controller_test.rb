# frozen_string_literal: true

require "test_helper"

class BoostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @post = posts(:root_post)
    @article = articles(:ruby_article)
  end

  test "POST create boosts a post" do
    sign_in_as(@user)

    assert_difference("Boost.count", 1) do
      post post_boost_path(@post), params: { boostable_type: "Post" }, as: :turbo_stream
    end

    assert_response :success
    assert @user.boosts?(@post)
    assert_equal 1, @post.reload.boosters_count
    assert_includes response.body, ">1<"
  end

  test "DELETE destroy updates count in response immediately" do
    sign_in_as(@user)
    @user.boost!(@post)

    delete post_boost_path(@post), params: { boostable_type: "Post" }, as: :turbo_stream

    assert_response :success
    assert_not @user.boosts?(@post)
    assert_equal 0, @post.reload.boosters_count
    assert_not_includes response.body, ">1<"
  end

  test "POST create requires authentication" do
    post post_boost_path(@post), params: { boostable_type: "Post" }

    assert_redirected_to new_user_session_path
  end

  test "POST create boosts an article" do
    sign_in_as(@user)

    assert_difference("Boost.count", 1) do
      post article_boost_path(@article), params: { boostable_type: "Article" }, as: :turbo_stream
    end

    assert_response :success
    assert @user.boosts?(@article)
    assert_equal 1, @article.reload.boosters_count
    assert_includes response.body, ">1<"
  end

  test "DELETE destroy updates article count in response immediately" do
    sign_in_as(@user)
    @user.boost!(@article)

    delete article_boost_path(@article), params: { boostable_type: "Article" }, as: :turbo_stream

    assert_response :success
    assert_not @user.boosts?(@article)
    assert_equal 0, @article.reload.boosters_count
    assert_not_includes response.body, ">1<"
  end


  test "웹 컨트롤러는 JSON 요청에 406으로 응답하며 상태를 바꾸지 않는다" do
    sign_in_as(@user)

    assert_no_difference("Boost.count") do
      post article_boost_path(@article), params: { boostable_type: "Article" }, as: :json
    end

    assert_response :not_acceptable
    assert_not @user.reload.boosts?(@article)
  end

  test "JSON DELETE도 406으로 끊기고 기존 반응을 지우지 않는다" do
    sign_in_as(@user)
    @user.boost!(@article)

    assert_no_difference("Boost.count") do
      delete article_boost_path(@article), params: { boostable_type: "Article" }, as: :json
    end

    assert_response :not_acceptable
    assert @user.reload.boosts?(@article)
  end
end
