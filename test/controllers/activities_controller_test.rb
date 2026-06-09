# test/controllers/activities_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
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

  test "GET feed excludes the current user's draft longform posts" do
    draft = posts(:longform_draft)
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
    admin_actor = federails_actors(:admin_actor)

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

    excluded_post = Post.create!(body: "excluded unfollowed post", user: users(:admin))
    Federails::Activity.create!(
      actor: admin_actor,
      entity: excluded_post,
      action: "Create",
      created_at: 30.minutes.ago,
      updated_at: 30.minutes.ago
    )

    sign_in_as(@user)
    get feed_path

    assert_response :success
    assert_includes @response.body, "newest own post"
    assert_includes @response.body, "older followed post"
    assert_not_includes @response.body, "excluded unfollowed post"
    assert_operator @response.body.index("newest own post"), :<, @response.body.index("older followed post")
    assert_includes @response.body, john_actor.name
    assert_includes @response.body, jane_actor.name
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
