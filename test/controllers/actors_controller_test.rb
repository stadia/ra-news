# test/controllers/actors_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class ActorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @actor = federails_actors(:john_actor)
  end

  test "GET show returns 200" do
    get actor_path(@actor)
    assert_response :success
  end

  test "GET show returns JSON" do
    get actor_path(@actor), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("username")
  end

  test "GET show returns 410 for tombstoned actor" do
    @actor.update!(tombstoned_at: Time.current)
    get actor_path(@actor)
    assert_response :gone
  end

  test "GET show returns 410 JSON for tombstoned actor" do
    @actor.update!(tombstoned_at: Time.current)
    get actor_path(@actor), as: :json
    assert_response :gone
    json = JSON.parse(response.body)
    assert_equal "Gone", json["error"]
  end

  test "GET lookup finds actor by account" do
    get lookup_actors_path(account: @actor.at_address)
    assert_response :success
  end

  test "GET lookup returns 404 for unknown account" do
    get lookup_actors_path(account: "nonexistent@example.com")
    assert_response :not_found
  end
end
