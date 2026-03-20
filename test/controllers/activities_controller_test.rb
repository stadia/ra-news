# test/controllers/activities_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
  end

  test "GET feed requires authentication" do
    get feed_path

    assert_redirected_to new_session_path
  end

  test "GET feed returns 200 for authenticated user" do
    sign_in_as(@user)
    get feed_path

    assert_response :success
  end

  test "GET feed includes current user and accepted followings in reverse chronological order" do
    john_actor = federails_actors(:john_actor)
    jane_actor = federails_actors(:jane_actor)
    admin_actor = federails_actors(:admin_actor)

    older_post = Post.create!(body: "older followed post", user: users(:jane))
    Federails::Activity.create!(
      actor: jane_actor,
      entity: older_post,
      action: "Create",
      created_at: 2.hours.ago,
      updated_at: 2.hours.ago
    )

    newest_post = Post.create!(body: "newest own post", user: @user)
    Federails::Activity.create!(
      actor: john_actor,
      entity: newest_post,
      action: "Create",
      created_at: 1.hour.ago,
      updated_at: 1.hour.ago
    )

    excluded_post = Post.create!(body: "excluded unfollowed post", user: users(:admin))
    Federails::Activity.create!(
      actor: admin_actor,
      entity: excluded_post,
      action: "Create",
      created_at: 30.minutes.ago,
      updated_at: 30.minutes.ago
    )

    sign_in_as(@user)
    get feed_path

    assert_response :success
    assert_includes @response.body, "newest own post"
    assert_includes @response.body, "older followed post"
    assert_not_includes @response.body, "excluded unfollowed post"
    assert_operator @response.body.index("newest own post"), :<, @response.body.index("older followed post")
    assert_includes @response.body, john_actor.name
    assert_includes @response.body, jane_actor.name
  end

  test "GET feed renders selected posts as a tree within the feed set" do
    followed_root = Post.create!(
      body: "followed root post",
      user: users(:jane),
      created_at: 2.hours.ago,
      updated_at: 2.hours.ago
    )
    own_reply = Post.create!(
      body: "own reply post",
      user: @user,
      parent: followed_root,
      created_at: 1.hour.ago,
      updated_at: 1.hour.ago
    )

    sign_in_as(@user)
    get feed_path

    assert_response :success
    assert_includes @response.body, "followed root post"
    assert_includes @response.body, "own reply post"
    assert_operator @response.body.index("followed root post"), :<, @response.body.index("own reply post")
  end
end
