# frozen_string_literal: true

require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "GET show renders user profile" do
    user = users(:john)

    get "/@#{user.username}"

    assert_response :success
  end

  test "GET show renders profile for Korean user" do
    user = users(:korean_user)

    get "/@#{user.username}"

    assert_response :success
  end

  test "GET show with nonexistent username renders 404" do
    get "/@nonexistent_user_xyz"

    assert_response :not_found
  end

  test "GET followers renders followers list" do
    user = users(:john)

    get "/@#{user.username}/followers"

    assert_response :success
  end

  test "GET following renders following list" do
    user = users(:john)

    get "/@#{user.username}/following"

    assert_response :success
  end

  test "GET followers as Turbo frame renders partial" do
    user = users(:john)

    get "/@#{user.username}/followers", headers: { "Turbo-Frame" => "true" }

    assert_response :success
  end

  test "GET following as Turbo frame renders partial" do
    user = users(:john)

    get "/@#{user.username}/following", headers: { "Turbo-Frame" => "true" }

    assert_response :success
  end
end
