# frozen_string_literal: true

require "test_helper"

class FollowingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @john = users(:john)
    @jane = users(:jane)
    @jane_actor = federails_actors(:jane_actor)
    @korean_user = users(:korean_user)
    @korean_actor = federails_actors(:korean_user_actor)
  end

  # --- Authentication ---

  test "POST create requires authentication" do
    post followings_path, params: { following: { target_actor_id: @jane_actor.id } }
    assert_redirected_to new_session_path
  end

  # --- new (remote follow) ---

  test "GET new redirects to actor show" do
    sign_in_as(@john)
    get new_following_path(uri: @jane_actor.federated_url)
    assert_redirected_to actor_path(@jane_actor)
  end

  # --- create ---

  test "POST create with target_actor_id creates following" do
    sign_in_as(@john)
    assert_difference "Federails::Following.count", 1 do
      post followings_path, params: { following: { target_actor_id: @korean_actor.id } }
    end
  end

  # --- follow ---

  test "POST follow creates following and responds with turbo_stream" do
    sign_in_as(@john)
    post follow_followings_path,
      params: { account: @korean_actor.at_address },
      as: :turbo_stream

    assert_response :success
    assert_includes response.body, "follow_actions_#{@korean_actor.id}"
  end

  test "POST follow responds with json" do
    sign_in_as(@john)
    post follow_followings_path,
      params: { account: @korean_actor.at_address },
      as: :json

    assert_response :created
  end

  test "POST follow with invalid account returns error" do
    sign_in_as(@john)
    post follow_followings_path,
      params: { account: "nonexistent@example.com" },
      as: :json

    assert_response :unprocessable_entity
  end

  # --- accept ---

  test "PUT accept accepts pending following" do
    following = Federails::Following.create!(
      actor: @korean_actor,
      target_actor: @john.federails_actor,
      status: :pending
    )

    sign_in_as(@john)
    put accept_following_path(following), as: :turbo_stream

    assert_response :success
    assert_includes response.body, "follow_actions_#{@korean_actor.id}"
  end

  # --- destroy ---

  test "DELETE destroy removes following and responds with turbo_stream" do
    following = Federails::Following.create!(
      actor: @john.federails_actor,
      target_actor: @korean_actor
    )

    sign_in_as(@john)
    delete following_path(following), as: :turbo_stream

    assert_response :success
    assert_includes response.body, "follow_actions_#{@korean_actor.id}"
  end

  test "DELETE destroy responds with json" do
    following = Federails::Following.create!(
      actor: @john.federails_actor,
      target_actor: @korean_actor
    )

    sign_in_as(@john)
    delete following_path(following), as: :json

    assert_response :no_content
  end
end
