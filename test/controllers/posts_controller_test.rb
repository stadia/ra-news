# frozen_string_literal: true

require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "should create post" do
    assert_difference("Post.count") do
      post posts_url, params: { post: { body: "테스트 포스트입니다." } }, as: :turbo_stream
    end
    assert_response :success
    assert_includes @response.body, 'target="posts_list"'
    assert_match(/id="replies_\d+"/, @response.body)
  end

  test "should create reply post" do
    parent = Post.create!(body: "부모 포스트", user: @user)
    assert_difference("Post.count") do
      post posts_url, params: { post: { body: "답글입니다.", parent_id: parent.id } }, as: :turbo_stream
    end
    assert_response :success
    assert_includes @response.body, "target=\"post_#{parent.id}\""
    assert_includes @response.body, "target=\"replies_#{parent.id}\""
  end

  test "should reject empty body" do
    assert_no_difference("Post.count") do
      post posts_url, params: { post: { body: "" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "should require authentication" do
    get logout_url
    post posts_url, params: { post: { body: "test" } }
    assert_redirected_to new_session_url
  end
end
