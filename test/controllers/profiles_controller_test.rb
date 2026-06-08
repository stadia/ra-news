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

  test "GET show renders profile for username with dot" do
    user = User.create!(email: "dot-profile@example.com", username: "john.doe", name: "Dot User", password: "password123", confirmed_at: Time.current)

    get "/@#{user.username}"

    assert_response :success
  end

  test "GET show with nonexistent username renders 404" do
    get "/@nonexistent_user_xyz"

    assert_response :not_found
  end

  test "GET followers requires login and own profile" do
    user = users(:john)

    get "/@#{user.username}/followers"

    assert_response :redirect
  end

  test "GET followers as owner renders followers list" do
    user = users(:john)
    sign_in user

    get "/@#{user.username}/followers"

    assert_response :success
  end

  test "GET followers as other user redirects" do
    user = users(:john)
    other = users(:jane)
    sign_in other

    get "/@#{user.username}/followers"

    assert_response :redirect
  end

  test "GET following requires login and own profile" do
    user = users(:john)

    get "/@#{user.username}/following"

    assert_response :redirect
  end

  test "GET following as owner renders following list" do
    user = users(:john)
    sign_in user

    get "/@#{user.username}/following"

    assert_response :success
  end

  test "GET following as other user redirects" do
    user = users(:john)
    other = users(:jane)
    sign_in other

    get "/@#{user.username}/following"

    assert_response :redirect
  end

  test "GET followers as Turbo frame renders partial for owner" do
    user = users(:john)
    sign_in user

    get "/@#{user.username}/followers", headers: { "Turbo-Frame" => "true" }

    assert_response :success
  end

  test "GET following as Turbo frame renders partial for owner" do
    user = users(:john)
    sign_in user

    get "/@#{user.username}/following", headers: { "Turbo-Frame" => "true" }

    assert_response :success
  end

  test "GET comments as Turbo frame renders comment list" do
    user = users(:john)

    get "/@#{user.username}/comments", headers: { "Turbo-Frame" => "true" }

    assert_response :success
    assert_includes response.body, posts(:comment_post).body
    assert_includes response.body, I18n.t("profiles.activity_tabs.comments")
  end

  test "GET likes as owner Turbo frame renders liked articles and posts" do
    user = users(:john)
    sign_in user
    Like.create!(actor: user.federails_actor, likeable: articles(:ruby_article), created_at: Time.current)
    Like.create!(actor: user.federails_actor, likeable: posts(:root_post), created_at: 1.minute.ago)

    get "/@#{user.username}/likes", headers: { "Turbo-Frame" => "true" }

    assert_response :success
    assert_includes response.body, articles(:ruby_article).title_ko
    assert_includes response.body, posts(:root_post).body
  end

  test "posts page shows published longform posts" do
    sign_in users(:john)
    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, "발행된 긴 글"
  end

  test "posts page does not show drafts to public" do
    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    assert_not_includes response.body, "작성 중인 긴 글"
  end

  test "owner posts page shows draft management entry" do
    sign_in users(:john)
    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, "작성 중인 초안"
    assert_includes response.body, "작성 중인 긴 글"
    assert_select "a[href=?]", edit_longform_post_path(posts(:longform_draft))
  end

  test "owner draft entry offers a delete control" do
    sign_in users(:john)
    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    assert_select "form[action=?]", longform_post_path(posts(:longform_draft))
  end

  test "comments tab excludes discarded comments" do
    posts(:comment_post).discard!

    get user_profile_comments_url(username: users(:john).username)

    assert_response :success
    assert_not_includes response.body, posts(:comment_post).body
  end

  test "trash tab requires the owner" do
    sign_in users(:jane)

    get user_profile_trash_url(username: users(:john).username)

    assert_redirected_to user_profile_base_path(username: users(:john).username)
  end

  test "owner trash tab lists discarded longform posts" do
    sign_in users(:john)
    posts(:longform_published).discard!

    get user_profile_trash_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, "발행된 긴 글"
    assert_select "form[action=?]", undiscard_longform_post_path(posts(:longform_published))
    assert_select "form[action=?]", destroy_permanently_longform_post_path(posts(:longform_published))
  end

  test "owner trash tab shows empty state when nothing discarded" do
    sign_in users(:john)

    get user_profile_trash_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, I18n.t("profiles.trash_list.empty")
  end

  test "owner profile shows trash tab" do
    sign_in users(:john)

    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, I18n.t("profiles.activity_tabs.trash")
  end

  test "trash tab is hidden from other users" do
    sign_in users(:jane)

    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    assert_not_includes response.body, user_profile_trash_path(username: users(:john).username)
  end
end
