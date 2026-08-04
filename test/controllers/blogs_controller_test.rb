# typed: false
# frozen_string_literal: true

require "test_helper"

class BlogsControllerTest < ActionDispatch::IntegrationTest
  test "shows a published blog post with the reading layout to anyone" do
    post = posts(:blog_published)

    get user_profile_blog_post_url(username: post.user.username, slug: post)

    assert_response :success
    assert_includes response.body, post.title
  end

  test "draft blog post is not served to anonymous visitors" do
    draft = posts(:blog_draft)

    get user_profile_blog_post_url(username: draft.user.username, slug: draft)

    assert_response :not_found
  end

  test "draft blog post is not served to a non-owner" do
    draft = posts(:blog_draft)
    sign_in users(:jane)

    get user_profile_blog_post_url(username: draft.user.username, slug: draft)

    assert_response :not_found
  end

  test "owner can preview their own draft blog post" do
    draft = posts(:blog_draft)
    sign_in draft.user

    get user_profile_blog_post_url(username: draft.user.username, slug: draft)

    assert_response :success
  end

  test "discarded blog post is not served publicly" do
    post = posts(:blog_published)
    post.discard!

    get user_profile_blog_post_url(username: post.user.username, slug: post)

    assert_response :not_found
  end

  test "correct slug under the wrong username is not found" do
    post = posts(:blog_published)

    get user_profile_blog_post_url(username: users(:jane).username, slug: post)

    assert_response :not_found
  end
end
