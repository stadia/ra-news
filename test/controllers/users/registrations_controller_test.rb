# frozen_string_literal: true

require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @avatar_path = Rails.root.join("public/icon.png")
  end

  test "PATCH update로 프로필 이미지를 업로드할 수 있다" do
    sign_in_as(@user)

    patch user_registration_path, params: {
      user: {
        email: @user.email,
        name: @user.name,
        avatar: fixture_upload("first-avatar.png")
      }
    }

    assert_redirected_to edit_user_registration_path
    @user.reload

    assert_predicate @user.avatar, :attached?
  end

  test "PATCH update로 프로필 이미지를 교체할 수 있다" do
    sign_in_as(@user)
    @user.avatar.attach(io: File.open(@avatar_path), filename: "old-avatar.png", content_type: "image/png")
    old_blob_id = @user.avatar.blob_id

    patch user_registration_path, params: {
      user: {
        email: @user.email,
        name: @user.name,
        avatar: fixture_upload("replacement-avatar.png")
      }
    }

    assert_redirected_to edit_user_registration_path
    @user.reload

    assert_predicate @user.avatar, :attached?
    assert_not_equal old_blob_id, @user.avatar.blob_id
  end

  test "PATCH update로 프로필 이미지를 제거할 수 있다" do
    sign_in_as(@user)
    @user.avatar.attach(io: File.open(@avatar_path), filename: "old-avatar.png", content_type: "image/png")

    patch user_registration_path, params: {
      user: {
        email: @user.email,
        name: @user.name,
        remove_avatar: "1"
      }
    }

    assert_redirected_to edit_user_registration_path
    @user.reload

    assert_not @user.avatar.attached?
  end

  test "GET federails server actor는 프로필 icon url을 노출한다" do
    @user.avatar.attach(io: File.open(@avatar_path), filename: "avatar.png", content_type: "image/png")

    get federails.server_actor_path(@user.federails_actor), headers: { "Accept" => "application/activity+json" }

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "Image", json.dig("icon", "type")
    assert_match %r{\Ahttp://example\.com/rails/active_storage/disk/}, json.dig("icon", "url")
  end

  private

  def fixture_upload(filename)
    Rack::Test::UploadedFile.new(@avatar_path, "image/png", original_filename: filename)
  end
end
