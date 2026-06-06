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

  test "JSON boost create without token returns 401" do
    post article_boost_path(@article, format: :json),
         params: { boostable_type: "Article" },
         as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "JSON boost create with valid JWT succeeds" do
    post user_session_path,
         params: { user: { email: @user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]

    assert_predicate token, :present?

    post article_boost_path(@article, format: :json),
         params: { boostable_type: "Article" },
         headers: { "Authorization" => token },
         as: :json

    assert_includes [ 200, 201 ], response.status
    assert @user.reload.boosts?(@article)
  end
end
