# typed: true
# frozen_string_literal: true

require "test_helper"

class Api::V1::LikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @post = posts(:root_post)
    @article = articles(:ruby_article)
  end

  test "POST create likes a post" do
    sign_in_as(@user)

    assert_difference("Like.count", 1) do
      post api_v1_post_like_path(@post), params: { likeable_type: "Post" }, as: :turbo_stream
    end

    assert_response :success
    assert @user.likes?(@post)
    assert_equal 1, @post.reload.likers_count
    assert_includes response.body, ">1<"
  end

  test "DELETE destroy updates count in response immediately" do
    sign_in_as(@user)
    @user.like!(@post)

    delete api_v1_post_like_path(@post), params: { likeable_type: "Post" }, as: :turbo_stream

    assert_response :success
    assert_not @user.likes?(@post)
    assert_equal 0, @post.reload.likers_count
    assert_not_includes response.body, ">1<"
  end

  test "POST create requires authentication" do
    post api_v1_post_like_path(@post), params: { likeable_type: "Post" }

    assert_redirected_to new_user_session_path
  end

  test "POST create likes an article" do
    sign_in_as(@user)

    assert_difference("Like.count", 1) do
      post api_v1_article_like_path(@article), params: { likeable_type: "Article" }, as: :turbo_stream
    end

    assert_response :success
    assert @user.likes?(@article)
    assert_equal 1, @article.reload.likers_count
    assert_includes response.body, ">1<"
  end

  test "DELETE destroy updates article count in response immediately" do
    sign_in_as(@user)
    @user.like!(@article)

    delete api_v1_article_like_path(@article), params: { likeable_type: "Article" }, as: :turbo_stream

    assert_response :success
    assert_not @user.likes?(@article)
    assert_equal 0, @article.reload.likers_count
    assert_not_includes response.body, ">1<"
  end

  test "JSON like create without token returns 401" do
    post api_v1_article_like_path(@article, format: :json),
         params: { likeable_type: "Article" },
         as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "JSON like create with valid JWT succeeds" do
    post user_session_path,
         params: { user: { email: @user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]

    assert_predicate token, :present?

    post api_v1_article_like_path(@article, format: :json),
         params: { likeable_type: "Article" },
         headers: { "Authorization" => token },
         as: :json

    assert_includes [ 200, 201 ], response.status
    assert @user.reload.likes?(@article)
  end
end
