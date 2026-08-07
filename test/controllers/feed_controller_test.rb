# test/controllers/activities_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class FeedControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
  end

  test "GET feed requires authentication" do
    get feed_path

    assert_redirected_to new_user_session_path
  end

  test "GET feed returns 200 for authenticated user" do
    sign_in_as(@user)
    get feed_path

    assert_response :success
  end

  test "GET feed excludes the current user's draft blog posts" do
    draft = posts(:blog_draft)
    sign_in_as(@user)

    get feed_path

    assert_response :success
    assert_not_includes @response.body, draft.title
  end

  test "GET feed preloads liked posts for authenticated user" do
    post = Post.create!(body: "liked feed post", user: @user)
    Like.create!(actor: @user.federails_actor, likeable: post, created_at: Time.current)

    sign_in_as(@user)

    like_queries = capture_like_queries do
      get feed_path
    end

    assert_response :success
    assert_includes @response.body, "liked feed post"
    assert_equal 1, like_queries.size
  end

  test "GET feed includes replies as flat posts in reverse chronological order" do
    root = Post.create!(body: "root post", user: @user, created_at: 2.hours.ago, updated_at: 2.hours.ago)
    Post.create!(body: "reply post", user: users(:jane), parent: root, created_at: 10.minutes.ago, updated_at: 10.minutes.ago)

    sign_in_as(@user)
    get feed_path

    assert_response :success
    assert_includes @response.body, "root post"
    assert_includes @response.body, "reply post"
    assert_includes @response.body, "#{@user.name}님에게 답글"
    assert_operator @response.body.index("reply post"), :<, @response.body.index("root post")
  end

  test "GET feed includes current user and accepted followings in reverse chronological order" do
    john_actor = federails_actors(:john_actor)
    jane_actor = federails_actors(:jane_actor)

    older_post = Post.create!(body: "older followed post", user: users(:jane))
    Federails::Activity.create!(
      actor: jane_actor,
      entity: older_post,
      action: "Create",
      created_at: 2.hours.ago,
      updated_at: 2.hours.ago
    )

    newest_post = Post.create!(body: "newest own post", user: @user)
    Federails::Activity.create!(
      actor: john_actor,
      entity: newest_post,
      action: "Create",
      created_at: 1.hour.ago,
      updated_at: 1.hour.ago
    )

    remote_actor = Federails::Actor.create!(
      federated_url: "https://remote.example/users/stranger",
      username: "stranger",
      name: "Stranger",
      server: "remote.example",
      inbox_url: "https://remote.example/users/stranger/inbox",
      outbox_url: "https://remote.example/users/stranger/outbox",
      followers_url: "https://remote.example/users/stranger/followers",
      followings_url: "https://remote.example/users/stranger/following",
      profile_url: "https://remote.example/@stranger",
      actor_type: "Person",
      local: false
    )
    excluded_post = Post.create!(
      body: "excluded unfollowed remote post",
      federails_actor: remote_actor,
      federated_url: "https://remote.example/notes/excluded",
      created_at: 30.minutes.ago,
      updated_at: 30.minutes.ago
    )

    sign_in_as(@user)
    get feed_path

    assert_response :success
    assert_includes @response.body, "newest own post"
    assert_includes @response.body, "older followed post"
    assert_not_includes @response.body, excluded_post.body
    assert_operator @response.body.index("newest own post"), :<, @response.body.index("older followed post")
    assert_includes @response.body, john_actor.name
    assert_includes @response.body, jane_actor.name
  end

  test "GET feed includes posts from local actors even when not followed" do
    admin_actor = federails_actors(:admin_actor)

    local_unfollowed_post = Post.create!(body: "local unfollowed post", user: users(:admin))
    Federails::Activity.create!(
      actor: admin_actor,
      entity: local_unfollowed_post,
      action: "Create",
      created_at: 30.minutes.ago,
      updated_at: 30.minutes.ago
    )

    refute Federails::Following.accepted.exists?(actor: @user.federails_actor, target_actor: admin_actor),
      "test premise: john must not follow admin"

    sign_in_as(@user)
    get feed_path

    assert_response :success
    assert_includes @response.body, "local unfollowed post"
  end

  test "GET feed renders article preview for posts linked to an article" do
    article = articles(:one)
    post = Post.create!(
      body: "article linked post",
      user: @user,
      article: article,
      created_at: 1.hour.ago,
      updated_at: 1.hour.ago
    )

    sign_in_as(@user)
    get feed_path

    assert_response :success
    assert_includes @response.body, post.body
    assert_includes @response.body, "연결된 기사"
    assert_includes @response.body, article.title_ko || article.title
  end

  test "GET first feed page nests the next page frame inside posts_list" do
    21.times do |index|
      Post.create!(
        body: "paged post #{index}",
        user: @user,
        created_at: index.minutes.ago,
        updated_at: index.minutes.ago
      )
    end

    sign_in_as(@user)
    get feed_path

    assert_response :success
    assert_select "#posts_list turbo-frame#feed_page_2.block.space-y-4", 1
    assert_select "#posts_list turbo-frame#feed_page_2.feed-scroll-sentinel[data-controller='infinite-scroll'][data-infinite-scroll-preload-margin-value='640px']", 1
    assert_includes @response.body, %(data-infinite-scroll-src-value="#{feed_path(page: 2)}")
    assert_select "#posts_list turbo-frame#feed_page_2 .feed-scroll-loader .feed-scroll-loader__content", text: "불러오는 중..."
  end

  test "GET second feed page uses the turbo frame as the spacing container" do
    21.times do |index|
      Post.create!(
        body: "paged post #{index}",
        user: @user,
        created_at: index.minutes.ago,
        updated_at: index.minutes.ago
      )
    end

    sign_in_as(@user)
    get feed_path(page: 2)

    assert_response :success
    assert_select "turbo-frame#feed_page_2.block.space-y-4", 1
    assert_select "turbo-frame#feed_page_2.feed-scroll-sentinel", 1
  end

  test "GET feed reply button targets the shared post form" do
    post = Post.create!(body: "reply target post", user: @user)

    sign_in_as(@user)
    get feed_path

    assert_response :success
    assert_includes @response.body, 'data-controller="feed-reply"'
    assert_includes @response.body, 'data-action="feed-reply#activate"'
    assert_includes @response.body, "post-form:reply@window->post-form#activateReply"
    assert_includes @response.body, %(feed-reply-parent-id-value="#{post.id}")
  end

  test "GET feed as JSON returns posts and pagination" do
    sign_in_as(@user)
    get feed_path, headers: { "Accept" => "application/json" }

    assert_response :success
    json = JSON.parse(@response.body)

    assert json.key?("posts"), "Response should contain posts key"
    assert json.key?("pagination"), "Response should contain pagination key"
    assert_kind_of Array, json["posts"]
    assert json["pagination"].key?("limit")
  end

  test "GET feed as JSON requires authentication" do
    get feed_path, headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end

  test "GET feed as JSON includes liked and boosted state" do
    own_post = Post.create!(body: "own json post", user: @user)
    Like.create!(actor: @user.federails_actor, likeable: own_post)

    sign_in_as(@user)
    get feed_path, headers: { "Accept" => "application/json" }

    assert_response :success
    json = JSON.parse(@response.body)
    own_post_data = json["posts"].find { |p| p["id"] == own_post.id }

    assert_not_nil own_post_data, "Own post should appear in feed"
    assert own_post_data["liked"], "Own liked post should have liked: true"
    refute own_post_data["boosted"], "Unboosted post should have boosted: false"
    assert own_post_data.key?("author_avatar_url"), "Post should expose author_avatar_url key"
  end

  private

  def capture_like_queries
    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql]
      next unless sql&.include?('"likes"')
      next unless payload[:name] != "SCHEMA"

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      yield
    end

    queries
  end
end
