# frozen_string_literal: true

require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @user = users(:john)
    @root_post = posts(:root_post)
    @reply_post = posts(:reply_post)
    @remote_post = posts(:remote_post)
    @comment_post = posts(:comment_post)
    @article = articles(:ruby_article)
  end

  # ========== Validation Tests ==========

  test "user가 있는 post는 유효하다" do
    post = Post.new(body: "테스트 포스트", user: @user)

    assert_predicate post, :valid?, post.errors.full_messages.join(", ")
  end

  test "federails_actor가 있는 post는 유효하다" do
    actor = federails_actors(:john_actor)
    post = Post.new(body: "리모트 포스트", federails_actor: actor, federated_url: "https://example.com/notes/1")

    assert_predicate post, :valid?, post.errors.full_messages.join(", ")
  end

  test "user도 federails_actor도 없으면 유효하지 않다" do
    post = Post.new(body: "고아 포스트")

    assert_not post.valid?
    assert_predicate post.errors[:base], :any?
  end

  test "body는 필수" do
    post = Post.new(user: @user)

    assert_not post.valid?
    assert_predicate post.errors[:body], :any?
  end

  test "body가 빈 문자열이면 유효하지 않다" do
    post = Post.new(body: "", user: @user)

    assert_not post.valid?
  end

  # ========== Nested Set Tests ==========

  test "root post는 parent가 없다" do
    assert_nil @root_post.parent_id
  end

  test "reply는 parent가 있다" do
    assert_equal @root_post.id, @reply_post.parent_id
  end

  test "root post는 children을 가진다" do
    assert_includes @root_post.children, @reply_post
  end

  # ========== Federation Tests ==========

  test "federation_actor_entity는 user를 반환한다 (로컬)" do
    assert_equal @root_post.user, @root_post.federation_actor_entity
  end

  test "federation_actor_entity는 federails_actor를 반환한다 (리모트)" do
    assert_equal @remote_post.federails_actor, @remote_post.federation_actor_entity
  end

  test "should_federate?는 entity가 있으면 true" do
    assert_predicate @root_post, :should_federate?
  end

  test "federails 좋아요 콜백으로 좋아요와 취소를 처리한다" do
    actor = Federails::Actor.create!(
      federated_url: "https://remote.example/users/post-liker-#{SecureRandom.hex(4)}",
      username: "post_liker",
      name: "Post Liker",
      server: "remote.example",
      inbox_url: "https://remote.example/users/post-liker/inbox",
      outbox_url: "https://remote.example/users/post-liker/outbox",
      followers_url: "https://remote.example/users/post-liker/followers",
      followings_url: "https://remote.example/users/post-liker/following",
      profile_url: "https://remote.example/@post-liker",
      actor_type: "Person",
      local: false
    )

    actor_payload = { "id" => actor.federated_url }

    assert_difference -> { Like.where(liker: actor, likeable: @root_post).count }, 1 do
      @root_post.apply_like(actor_payload)
    end

    assert_difference -> { Like.where(liker: actor, likeable: @root_post).count }, -1 do
      @root_post.apply_unlike(actor_payload)
    end
  end

  # ========== Article Comment Tests ==========

  test "comment?는 article_id가 있으면 true를 반환한다" do
    assert_predicate @comment_post, :comment?
  end

  test "comment?는 article_id가 없으면 false를 반환한다" do
    assert_not @root_post.comment?
  end

  test "reply는 parent가 있으면 parent를 반환한다" do
    assert_equal @root_post, @reply_post.reply
  end

  test "reply는 parent가 없고 article이 있으면 article을 반환한다" do
    assert_equal @article, @comment_post.reply
  end

  test "author_name은 user의 full_name을 반환한다" do
    assert_equal @user.full_name, @root_post.author_name
  end

  test "author_name은 user가 없으면 federails_actor의 username을 반환한다" do
    assert_equal @remote_post.federails_actor.username, @remote_post.author_name
  end

  test "author_name은 user도 actor도 없으면 익명을 반환한다" do
    post = Post.new(body: "test")
    assert_equal "익명", post.author_name
  end

  test "author_host는 federails_actor가 있으면 서버 정보를 반환한다" do
    assert_equal "(#{@remote_post.federails_actor.server})", @remote_post.author_host
  end

  test "author_host는 federails_actor가 없으면 nil을 반환한다" do
    assert_nil @root_post.author_host
  end

  # ========== Scope Tests ==========

  test "comments 스코프는 article_id가 있는 post만 반환한다" do
    comments = Post.comments
    assert_includes comments, @comment_post
    assert_not_includes comments, @root_post
  end

  test "standalone 스코프는 article_id가 없는 post만 반환한다" do
    standalone = Post.standalone
    assert_includes standalone, @root_post
    assert_not_includes standalone, @comment_post
  end

  # ========== handle_federated_object? Tests ==========

  # ========== Reply Notification Tests ==========

  test "답글 생성 시 ReplyNotificationJob이 큐에 추가된다" do
    other_user = users(:jane)
    assert_enqueued_with(job: ReplyNotificationJob) do
      Post.create!(body: "답글입니다", user: other_user, parent: @root_post)
    end
  end

  test "루트 post 생성 시 ReplyNotificationJob이 큐에 추가되지 않는다" do
    assert_no_enqueued_jobs(only: ReplyNotificationJob) do
      Post.create!(body: "루트 포스트", user: @user)
    end
  end

  test "자기 자신에게 답글 달면 알림이 가지 않는다" do
    assert_no_enqueued_jobs(only: ReplyNotificationJob) do
      Post.create!(body: "셀프 답글", user: @user, parent: @root_post)
    end
  end

  test "parent에 user가 없으면 알림이 가지 않는다" do
    actor = federails_actors(:john_actor)
    remote_root = Post.create!(body: "리모트 루트", federails_actor: actor, federated_url: "https://remote.example/notes/rr1")
    assert_no_enqueued_jobs(only: ReplyNotificationJob) do
      Post.create!(body: "로컬 답글", user: @user, parent: remote_root)
    end
  end

  # ========== handle_federated_object? Tests ==========

  test "inReplyTo가 없는 Note를 수락한다" do
    hash = { "type" => "Note", "content" => "Hello" }

    assert Post.handle_federated_object?(hash)
  end

  test "inReplyTo가 외부 URL이면 거부한다" do
    hash = { "type" => "Note", "inReplyTo" => "https://example.com/some/external/post" }

    assert_not Post.handle_federated_object?(hash)
  end

  test "inReplyTo가 로컬 article URL이면 수락한다" do
    local_host = Rails.application.routes.default_url_options[:host] || "www.example.com"
    hash = { "type" => "Note", "inReplyTo" => "http://#{local_host}/articles/#{@article.id}" }

    assert Post.handle_federated_object?(hash)
  end

  test "inReplyTo가 로컬 post를 가리키면 수락한다" do
    local_host = Rails.application.routes.default_url_options[:host] || "www.example.com"
    hash = { "type" => "Note", "inReplyTo" => "http://#{local_host}/posts/#{@root_post.id}" }

    assert Post.handle_federated_object?(hash)
  end

  test "inReplyTo가 리모트 post의 federated_url이면 수락한다" do
    hash = { "type" => "Note", "inReplyTo" => @remote_post.federated_url }

    assert Post.handle_federated_object?(hash)
  end

  # ========== from_activitypub_object Tests ==========

  test "from_activitypub_object는 body를 HTML strip한다" do
    hash = { "id" => "https://remote.example.com/notes/456", "content" => "<p>Hello <b>world</b></p>" }
    result = Post.from_activitypub_object(hash)

    assert_equal "Hello world", result[:body]
    assert_equal "https://remote.example.com/notes/456", result[:federated_url]
  end

  test "from_activitypub_object는 로컬 post URL에서 parent_id를 추출한다" do
    hash = {
      "id" => "https://remote.example.com/notes/999",
      "content" => "로컬 답글",
      "inReplyTo" => "http://www.example.com/posts/#{@root_post.id}"
    }
    result = Post.from_activitypub_object(hash)

    assert_equal @root_post.id.to_s, result[:parent_id]
  end

  test "from_activitypub_object는 inReplyTo로 parent를 찾는다" do
    hash = {
      "id" => "https://remote.example.com/notes/789",
      "content" => "답글",
      "inReplyTo" => @remote_post.federated_url
    }
    result = Post.from_activitypub_object(hash)

    assert_equal @remote_post.id, result[:parent_id]
  end

  test "from_activitypub_object는 article URL에서 article_id를 추출한다" do
    hash = {
      "id" => "https://remote.example.com/notes/art1",
      "content" => "기사 댓글",
      "inReplyTo" => "http://www.example.com/articles/#{@article.id}"
    }
    result = Post.from_activitypub_object(hash)

    assert_equal @article.id.to_s, result[:article_id]
    assert_nil result[:parent_id]
  end
end
