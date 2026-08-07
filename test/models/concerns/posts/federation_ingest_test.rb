# frozen_string_literal: true

require "test_helper"

# Direct coverage for the extracted Posts::FederationIngest concern (inbound
# ActivityPub parsing). Reply-target resolution is also exercised in
# post_test.rb; these tests pin the currently-undocumented edge cases:
# article_id value-type inconsistency, discarded-parent resolution, hashtag
# prefix handling, and the missing-id path.
class Posts::FederationIngestTest < ActiveSupport::TestCase
  def setup
    @article = articles(:ruby_article)
    @root_post = posts(:root_post)
    @comment_post = posts(:comment_post) # post_type :comment, belongs to ruby_article
    @local_host = Rails.application.routes.default_url_options[:host] || "www.example.com"
  end

  # ── article_id value type (regex capture vs DB column) ──────────────
  #
  # The /articles/N branch yields a String (regex capture) while the
  # federated-parent branch yields an Integer. Pinned so a future
  # normalization is a deliberate, visible change.

  test "article_id from a local /articles/ URL is a String" do
    hash = { "id" => "https://remote.example.com/notes/a", "content" => "댓글",
             "inReplyTo" => "https://#{@local_host}/articles/#{@article.id}" }
    result = Post.from_activitypub_object(hash)

    assert_equal @article.id.to_s, result[:article_id]
    assert_kind_of String, result[:article_id]
    assert_equal :comment, result[:post_type]
  end

  test "article_id from a federated parent is an Integer" do
    parent = Post.create!(body: "미러링된 리모트 기사", federails_actor: federails_actors(:john_actor),
                          federated_url: "https://hackers.pub/ap/notes/parent-1", article: @article)
    hash = { "id" => "https://hackers.pub/ap/notes/child-1", "content" => "답글",
             "inReplyTo" => "https://hackers.pub/ap/notes/parent-1" }
    result = Post.from_activitypub_object(hash)

    assert_equal parent.id, result[:parent_id]
    assert_equal @article.id, result[:article_id]
    assert_kind_of Integer, result[:article_id]
  end

  # ── discarded parent (verified actual behavior) ─────────────────────
  #
  # Post has no `kept` default_scope, so Post.find_by / Post.exists? DO see
  # soft-deleted rows. A reply to a discarded parent therefore resolves
  # normally rather than being orphaned. Pinned to lock in the real behavior.

  test "reply to a discarded federated parent still resolves parent_id and article_id" do
    parent = Post.create!(body: "삭제된 원격 부모", federails_actor: federails_actors(:john_actor),
                          federated_url: "https://remote.example.com/notes/discarded", article: @article)
    parent.discard!

    hash = { "id" => "https://remote.example.com/notes/reply-to-discarded", "content" => "답글",
             "inReplyTo" => "https://remote.example.com/notes/discarded" }
    result = Post.from_activitypub_object(hash)

    assert_equal parent.id, result[:parent_id]
    assert_equal @article.id, result[:article_id]
  end

  test "handle_federated_object? accepts a reply to a discarded parent's federated_url" do
    parent = Post.create!(body: "삭제된 원격 부모", federails_actor: federails_actors(:john_actor),
                          federated_url: "https://remote.example.com/notes/discarded-2")
    parent.discard!

    hash = { "type" => "Note", "inReplyTo" => "https://remote.example.com/notes/discarded-2" }

    assert Post.send(:handle_federated_object?, hash)
  end

  # ── local /posts/ branch ────────────────────────────────────────────

  test "local /posts/ URL pointing at a comment fills both parent_id and article_id" do
    hash = { "id" => "https://remote.example.com/notes/b", "content" => "답글",
             "inReplyTo" => "https://#{@local_host}/posts/#{@comment_post.id}" }
    result = Post.from_activitypub_object(hash)

    assert_equal @comment_post.id.to_s, result[:parent_id]
    assert_equal @comment_post.article_id, result[:article_id]
  end

  # ── hashtag parsing ─────────────────────────────────────────────────

  test "hashtags are stripped of leading # deduplicated and comma-joined" do
    hash = { "id" => "https://remote.example.com/notes/tags", "content" => "본문",
             "tag" => [
               { "type" => "Hashtag", "name" => "#ruby" },
               { "type" => "Hashtag", "name" => "rails" },
               { "type" => "Hashtag", "name" => "#ruby" },
               { "type" => "Mention", "name" => "@someone" }
             ] }
    result = Post.from_activitypub_object(hash)

    assert_equal "ruby, rails", result[:tag_list]
  end

  test "tag_list is absent when there are no hashtags" do
    hash = { "id" => "https://remote.example.com/notes/notags", "content" => "본문" }
    result = Post.from_activitypub_object(hash)

    assert_not result.key?(:tag_list)
  end

  # ── federated_url / missing id ──────────────────────────────────────

  test "federated_url mirrors the object id and is nil when id is missing" do
    with_id = Post.from_activitypub_object({ "id" => "https://remote.example.com/notes/c", "content" => "본문" })
    without_id = Post.from_activitypub_object({ "content" => "본문" })

    assert_equal "https://remote.example.com/notes/c", with_id[:federated_url]
    assert_nil without_id[:federated_url]
  end

  # ── no inReplyTo → no reply attributes ──────────────────────────────

  test "an object without inReplyTo carries no reply attributes" do
    result = Post.from_activitypub_object({ "id" => "https://remote.example.com/notes/root", "content" => "원문" })

    assert_not result.key?(:parent_id)
    assert_not result.key?(:article_id)
    assert_not result.key?(:post_type)
  end
end
