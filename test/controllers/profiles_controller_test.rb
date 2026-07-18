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

  test "GET likes as other user redirects to profile with alert" do
    user = users(:john)
    other = users(:jane)
    sign_in other

    get "/@#{user.username}/likes"

    assert_redirected_to user_profile_base_path(username: user.username)
    assert_equal "본인만 볼 수 있습니다", flash[:alert]
  end

  test "GET likes requires login" do
    user = users(:john)

    get "/@#{user.username}/likes"

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "posts page shows published blog posts" do
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

  test "owner posts page no longer renders drafts" do
    sign_in users(:john)
    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    # 초안은 더 이상 글 탭이 아니라 장문 탭에서 관리한다.
    assert_not_includes response.body, posts(:blog_draft).title
    assert_select "a[href=?]", edit_blog_post_path(posts(:blog_draft)), count: 0
  end

  test "public blog tab lists published blog posts to anyone" do
    get user_profile_blog_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, posts(:blog_published).title
    assert_select "a[href=?]", user_profile_blog_post_path(username: users(:john).username, slug: posts(:blog_published))
  end

  test "public blog tab excludes drafts and trash" do
    posts(:blog_published).discard!

    get user_profile_blog_url(username: users(:john).username)

    assert_response :success
    assert_not_includes response.body, posts(:blog_draft).title
    assert_not_includes response.body, posts(:blog_published).title
  end

  test "comments tab excludes discarded comments" do
    posts(:comment_post).discard!

    get user_profile_comments_url(username: users(:john).username)

    assert_response :success
    assert_not_includes response.body, posts(:comment_post).body
  end

  test "owner profile shows blog tab" do
    sign_in users(:john)

    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, I18n.t("profiles.activity_tabs.blog")
  end

  test "blog tab is visible to other users" do
    sign_in users(:jane)

    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, user_profile_blog_path(username: users(:john).username)
  end

  test "GET boosts as anonymous user renders boosted articles and posts" do
    user = users(:john)
    Boost.create!(actor: user.federails_actor, boostable: articles(:ruby_article), created_at: Time.current)
    Boost.create!(actor: user.federails_actor, boostable: posts(:root_post), created_at: 1.minute.ago)

    get "/@#{user.username}/boosts"

    assert_response :success
    assert_includes response.body, articles(:ruby_article).title_ko
    assert_includes response.body, posts(:root_post).body
  end

  test "boosts tab is visible to other users" do
    sign_in users(:jane)

    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, user_profile_boosts_path(username: users(:john).username)
  end
end
