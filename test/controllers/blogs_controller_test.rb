# frozen_string_literal: true

require "test_helper"

class BlogsControllerTest < ActionDispatch::IntegrationTest
  test "shows a published blog post with the reading layout to anyone" do
    post = posts(:blog_published)

    get user_profile_blog_post_url(username: post.user.username, slug: post)

    assert_response :success
    assert_includes response.body, post.title
  end

  # 마스토돈 등 원격 클라이언트가 링크 프리뷰 카드를 만들 수 있도록,
  # 장문 상세는 요약을 og:description으로 노출한다.
  test "published blog post exposes article open graph tags" do
    post = posts(:blog_published)

    get user_profile_blog_post_url(username: post.user.username, slug: post)

    assert_includes response.body, %(<meta property="og:type" content="article">)
    assert_includes response.body, %(content="#{post.blog_summary}")
    assert_includes response.body, %(<meta property="og:title" content="#{post.title}">)
  end

  test "blog post with a body image uses it as the preview card image" do
    post = posts(:blog_published)
    post.update!(body: %(<p>본문</p><img src="/uploads/cover.png">))

    get user_profile_blog_post_url(username: post.user.username, slug: post)

    assert_includes response.body, %(<meta property="og:image" content="http://example.com/uploads/cover.png">)
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
