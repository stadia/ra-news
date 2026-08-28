# frozen_string_literal: true

require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in @user
  end

  test "should create post" do
    assert_difference("Post.count") do
      post posts_url, params: { post: { body: "테스트 포스트입니다." } }, as: :turbo_stream
    end
    assert_response :success
    assert_includes @response.body, 'target="posts_list"'
    assert_match(/id="replies_\d+"/, @response.body)
  end

  test "turbo_stream 응답은 HTML 레이아웃으로 감싸지지 않는다" do
    # 레이아웃 proc이 turbo_stream일 때 false를 반환하는지 지킨다. 기존 단언들은
    # 부분 문자열 검사라 통짜 HTML로 감싸여도 통과하므로, <html> 미포함을 직접
    # 단언해야 이 분기의 회귀를 잡는다(application_controller.rb:12).
    post posts_url, params: { post: { body: "레이아웃 확인" } }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    assert_no_match(/<html/i, @response.body)
  end

  test "should create reply post" do
    parent = Post.create!(body: "부모 포스트", user: users(:jane))
    assert_difference("Post.count") do
      post posts_url, params: { post: { body: "답글입니다.", parent_id: parent.id } }, as: :turbo_stream
    end
    assert_response :success
    assert_includes @response.body, "target=\"post_#{parent.id}\""
    assert_includes @response.body, 'target="posts_list"'
    created_post = Post.order(:id).last

    assert_includes created_post.body, %(href="#{Rails.application.routes.url_helpers.user_profile_url(parent.user)}")
    assert_includes created_post.body, "@jane"
  end

  test "should replace existing remote mention text with profile link in reply body" do
    actor = Fedipub::Actor.create!(
      federated_url: "https://remote.example/users/alice",
      username: "alice",
      name: "Alice",
      server: "remote.example",
      inbox_url: "https://remote.example/users/alice/inbox",
      outbox_url: "https://remote.example/users/alice/outbox",
      followers_url: "https://remote.example/users/alice/followers",
      followings_url: "https://remote.example/users/alice/following",
      profile_url: "https://remote.example/@alice",
      actor_type: "Person",
      local: false
    )
    parent = Post.create!(body: "리모트 부모 포스트", fedipub_actor: actor, federated_url: "https://remote.example/notes/1")

    assert_difference("Post.count") do
      post posts_url, params: { post: { body: "@alice@remote.example 집에 가서 해볼게", parent_id: parent.id } }, as: :turbo_stream
    end

    created_post = Post.order(:id).last

    assert_includes created_post.body, %(href="https://remote.example/@alice")
    assert_includes created_post.body, %(<a href="https://remote.example/@alice">@alice@remote.example</a> 집에 가서 해볼게)
  end

  test "should reject empty body" do
    assert_no_difference("Post.count") do
      post posts_url, params: { post: { body: "" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "should require authentication" do
    sign_out @user
    post posts_url, params: { post: { body: "test" } }

    assert_redirected_to new_user_session_url
  end

  test "should create article comment" do
    article = articles(:ruby_article)
    assert_difference("Post.count") do
      post article_posts_url(article), params: { post: { body: "테스트 댓글입니다." } }, as: :turbo_stream
    end
    assert_response :success
    assert_includes @response.body, 'target="comments_list"'
  end

  test "should destroy own article comment" do
    article = articles(:ruby_article)
    comment = Post.create!(body: "삭제할 댓글", user: @user, article: article)
    assert_difference("Post.count", -1) do
      delete article_post_url(article, comment), as: :turbo_stream
    end
    assert_response :success
  end

  test "JSON post create without token returns 401" do
    sign_out @user
    article = articles(:ruby_article)

    post article_posts_url(article, format: :json),
         params: { post: { body: "댓글" } },
         as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "blog post is not served at legacy /posts/:slug" do
    blog = posts(:blog_published)

    get post_url(blog)

    assert_response :not_found
  end

  test "short post is still served at /posts/:slug" do
    short = posts(:short_with_article)

    get post_url(short)

    assert_response :success
  end

  test "discarded comment does not appear in article comments" do
    article = articles(:ruby_article)
    comment = Post.create!(body: "삭제될 댓글", user: @user, article: article, post_type: :comment, status: :published)
    comment.discard!

    get article_url(article)

    assert_response :success
    assert_not_includes response.body, "삭제될 댓글"
  end
end
