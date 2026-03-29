# frozen_string_literal: true

require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @user = users(:john)
    @root_post = posts(:root_post)
    @reply_post = posts(:reply_post)
    @remote_post = posts(:remote_post)
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

  # ========== handle_federated_object? Tests ==========

  test "inReplyTo가 없는 Note를 수락한다" do
    hash = { "type" => "Note", "content" => "Hello" }

    assert Post.handle_federated_object?(hash)
  end

  test "inReplyTo가 있는 Note는 거부한다 (Comment가 처리)" do
    hash = { "type" => "Note", "inReplyTo" => "https://example.com/articles/1" }

    assert_not Post.handle_federated_object?(hash)
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
end
