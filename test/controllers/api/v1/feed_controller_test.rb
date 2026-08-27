# frozen_string_literal: true

require "test_helper"

class Api::V1::FeedControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
  end

  test "GET feed as JSON returns posts and pagination" do
    sign_in_as(@user)
    get api_v1_feed_path, headers: { "Accept" => "application/json" }

    assert_response :success
    json = JSON.parse(@response.body)

    assert json.key?("posts"), "Response should contain posts key"
    assert json.key?("pagination"), "Response should contain pagination key"
    assert_kind_of Array, json["posts"]
    assert json["pagination"].key?("limit")
  end

  test "GET feed as JSON requires authentication" do
    get api_v1_feed_path, headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end

  test "GET feed as JSON includes liked and boosted state" do
    own_post = Post.create!(body: "own json post", user: @user)
    Like.create!(actor: @user.federails_actor, likeable: own_post)

    sign_in_as(@user)
    get api_v1_feed_path, headers: { "Accept" => "application/json" }

    assert_response :success
    json = JSON.parse(@response.body)
    own_post_data = json["posts"].find { |p| p["id"] == own_post.id }

    assert_not_nil own_post_data, "Own post should appear in feed"
    assert own_post_data["liked"], "Own liked post should have liked: true"
    refute own_post_data["boosted"], "Unboosted post should have boosted: false"
    assert own_post_data.key?("author_avatar_url"), "Post should expose author_avatar_url key"
  end
end
