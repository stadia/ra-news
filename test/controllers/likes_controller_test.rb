# frozen_string_literal: true

require "test_helper"

class LikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @post = posts(:root_post)
    @article = articles(:ruby_article)
  end

  test "POST create likes a post" do
    sign_in_as(@user)

    assert_difference("Like.count", 1) do
      post post_like_path(@post), params: { likeable_type: "Post" }, as: :turbo_stream
    end

    assert_response :success
    assert @user.likes?(@post)
    assert_equal 1, @post.reload.likers_count
    assert_includes response.body, ">1<"
  end

  test "DELETE destroy updates count in response immediately" do
    sign_in_as(@user)
    @user.like!(@post)

    delete post_like_path(@post), params: { likeable_type: "Post" }, as: :turbo_stream

    assert_response :success
    assert_not @user.likes?(@post)
    assert_equal 0, @post.reload.likers_count
    assert_not_includes response.body, ">1<"
  end

  test "POST create requires authentication" do
    post post_like_path(@post), params: { likeable_type: "Post" }

    assert_redirected_to new_user_session_path
  end

  test "POST create likes an article" do
    sign_in_as(@user)

    assert_difference("Like.count", 1) do
      post article_like_path(@article), params: { likeable_type: "Article" }, as: :turbo_stream
    end

    assert_response :success
    assert @user.likes?(@article)
    assert_equal 1, @article.reload.likers_count
    assert_includes response.body, ">1<"
  end

  test "DELETE destroy updates article count in response immediately" do
    sign_in_as(@user)
    @user.like!(@article)

    delete article_like_path(@article), params: { likeable_type: "Article" }, as: :turbo_stream

    assert_response :success
    assert_not @user.likes?(@article)
    assert_equal 0, @article.reload.likers_count
    assert_not_includes response.body, ">1<"
  end


  test "웹 컨트롤러는 JSON 요청에 406으로 응답하며 상태를 바꾸지 않는다" do
    sign_in_as(@user)

    assert_no_difference("Like.count") do
      post article_like_path(@article), params: { likeable_type: "Article" }, as: :json
    end

    assert_response :not_acceptable
    assert_not @user.reload.likes?(@article)
  end

  test "JSON DELETE도 406으로 끊기고 기존 반응을 지우지 않는다" do
    sign_in_as(@user)
    @user.like!(@article)

    assert_no_difference("Like.count") do
      delete article_like_path(@article), params: { likeable_type: "Article" }, as: :json
    end

    assert_response :not_acceptable
    assert @user.reload.likes?(@article)
  end
end
