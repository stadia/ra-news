# test/controllers/activities_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
  end

  test "GET index requires authentication" do
    get activities_path
    assert_redirected_to new_session_path
  end

  test "GET index returns 200 for authenticated user" do
    sign_in_as(@user)
    get activities_path
    assert_response :success
  end

  test "GET feed requires authentication" do
    get feed_activities_path
    assert_redirected_to new_session_path
  end

  test "GET feed returns 200 for authenticated user" do
    sign_in_as(@user)
    get feed_activities_path
    assert_response :success
  end

  test "GET actor activities requires authentication" do
    actor = federails_actors(:john_actor)
    get actor_activities_path(actor)
    assert_redirected_to new_session_path
  end

  test "GET actor activities returns 200" do
    sign_in_as(@user)
    actor = federails_actors(:john_actor)
    get actor_activities_path(actor)
    assert_response :success
  end
end
