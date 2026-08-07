# frozen_string_literal: true

require "test_helper"

class LikeTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:john)
    @local_post = posts(:root_post)
    @local_article = articles(:ruby_article)
    @remote_actor = Federails::Actor.create!(
      federated_url: "https://remote.example/@alice",
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
    @remote_post = Post.create!(
      body: "원격 포스트",
      federails_actor: @remote_actor,
      federated_url: "https://remote.example/notes/1"
    )
    Article.insert!({
      title: "원격 아티클",
      title_ko: "원격 아티클",
      url: "https://remote.example/articles/1",
      origin_url: "https://remote.example/articles/1",
      host: "remote.example",
      slug: "remote-article-1",
      published_at: Time.zone.now,
      user_id: @user.id,
      federails_actor_id: @remote_actor.id,
      federated_url: "https://remote.example/articles/1",
      created_at: Time.current,
      updated_at: Time.current
    })
    @remote_article = Article.find_by!(url: "https://remote.example/articles/1")
  end

  test "local user liking a local post creates a public Like activity" do
    assert_difference("Federails::Activity.where(action: 'Like').count", 1) do
      @user.like!(@local_post)
    end

    activity = Federails::Activity.where(action: "Like").order(created_at: :desc).first

    assert_equal @user.federails_actor, activity.actor
    assert_equal @local_post, activity.entity
    assert_includes Array(activity.to), Fediverse::Collection::PUBLIC
    assert_includes Array(activity.cc), @user.federails_actor.followers_url
  end

  test "local user unliking a post creates an Undo activity referencing the Like" do
    @user.like!(@local_post)

    assert_difference("Federails::Activity.where(action: 'Undo').count", 1) do
      @user.unlike!(@local_post)
    end

    undo = Federails::Activity.where(action: "Undo").order(created_at: :desc).first

    assert_equal @user.federails_actor, undo.actor
    assert_instance_of Federails::Activity, undo.entity
    assert_equal "Like", undo.entity.action
  end

  test "local user liking a local article creates a public Like activity" do
    assert_difference("Federails::Activity.where(action: 'Like').count", 1) do
      @user.like!(@local_article)
    end

    activity = Federails::Activity.where(action: "Like").order(created_at: :desc).first

    assert_equal @user.federails_actor, activity.actor
    assert_equal @local_article, activity.entity
  end

  test "local user liking an article without a federation URL does not create an outbound activity" do
    @local_article.update_columns(title_ko: nil, deleted_at: Time.current)

    assert_no_difference("Federails::Activity.where(action: 'Like').count") do
      @user.like!(@local_article)
    end
  end

  test "local user liking a remote post creates an outbound Like activity" do
    assert_difference("Federails::Activity.where(action: 'Like').count", 1) do
      @user.like!(@remote_post)
    end

    activity = Federails::Activity.where(action: "Like").order(created_at: :desc).first

    assert_equal @user.federails_actor, activity.actor
    assert_equal @remote_post, activity.entity
  end

  test "local user unliking a remote post creates an Undo activity" do
    @user.like!(@remote_post)

    assert_difference("Federails::Activity.where(action: 'Undo').count", 1) do
      @user.unlike!(@remote_post)
    end

    undo = Federails::Activity.where(action: "Undo").order(created_at: :desc).first

    assert_instance_of Federails::Activity, undo.entity
    assert_equal "Like", undo.entity.action
  end

  test "remote actor like via inbound handler creates a Like row and updates counters" do
    activity = {
      "id" => "https://remote.example/activities/like-1",
      "type" => "Like",
      "actor" => @remote_actor.federated_url,
      "object" => @local_post.federated_url
    }

    assert_difference("Like.count", 1) do
      Fediverse::Inbox::LikeHandler.handle_like(activity)
    end

    assert_predicate @remote_actor.reload.likees_count, :positive?
    assert_equal 1, @local_post.reload.likers_count
    assert Like.exists?(actor: @remote_actor, likeable: @local_post)
  end

  test "inbound remote like does not produce an outbound Like activity" do
    activity = {
      "id" => "https://remote.example/activities/like-2",
      "type" => "Like",
      "actor" => @remote_actor.federated_url,
      "object" => @local_post.federated_url
    }

    assert_no_difference("Federails::Activity.where(action: 'Like', actor: @remote_actor).count") do
      Fediverse::Inbox::LikeHandler.handle_like(activity)
    end
  end

  test "Like.liked_ids_for accepts a User and returns matching likeable ids" do
    @user.like!(@local_post)

    ids = Like.liked_ids_for(
      liker: @user,
      likeable_type: "Post",
      likeable_ids: [ @local_post.id ]
    )

    assert_equal [ @local_post.id ], ids
  end

  test "Like.liked_ids_for returns empty for nil liker" do
    assert_equal [], Like.liked_ids_for(liker: nil, likeable_type: "Post", likeable_ids: [ @local_post.id ])
  end

  test "User#likes? reflects the underlying Like row" do
    refute @user.likes?(@local_post)
    @user.like!(@local_post)

    assert @user.likes?(@local_post)
    @user.unlike!(@local_post)

    refute @user.likes?(@local_post)
  end

  test "duplicate like by the same actor is rejected" do
    @user.like!(@local_post)
    assert_no_difference("Like.count") do
      @user.like!(@local_post)
    end
  end

  test "liking an article without a thumbnail enqueues ArticleThumbnailJob" do
    refute_predicate @local_article.thumbnail, :attached?

    assert_enqueued_with(job: ArticleThumbnailJob, args: [ @local_article.id ]) do
      @user.like!(@local_article)
    end
  end

  test "liking an article that already has a thumbnail does not enqueue ArticleThumbnailJob" do
    @local_article.thumbnail.attach(
      io: StringIO.new("thumbnail-bytes"),
      filename: "thumb.png",
      content_type: "image/png"
    )

    assert_no_enqueued_jobs(only: ArticleThumbnailJob) do
      @user.like!(@local_article)
    end
  end

  test "liking a post does not enqueue ArticleThumbnailJob" do
    assert_no_enqueued_jobs(only: ArticleThumbnailJob) do
      @user.like!(@local_post)
    end
  end
end
