# typed: false
# frozen_string_literal: true

require "test_helper"

class BoostTest < ActiveSupport::TestCase
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

  test "local user boosting a local post creates a public Announce activity" do
    assert_difference("Federails::Activity.where(action: 'Announce').count", 1) do
      @user.boost!(@local_post)
    end

    activity = Federails::Activity.where(action: "Announce").order(created_at: :desc).first

    assert_equal @user.federails_actor, activity.actor
    assert_equal @local_post, activity.entity
    assert_includes Array(activity.to), Fediverse::Collection::PUBLIC
    assert_includes Array(activity.cc), @user.federails_actor.followers_url
  end

  test "local user unboosting a post creates an Undo activity referencing the Announce" do
    @user.boost!(@local_post)

    assert_difference("Federails::Activity.where(action: 'Undo').count", 1) do
      @user.unboost!(@local_post)
    end

    undo = Federails::Activity.where(action: "Undo").order(created_at: :desc).first

    assert_equal @user.federails_actor, undo.actor
    assert_instance_of Federails::Activity, undo.entity
    assert_equal "Announce", undo.entity.action
  end

  test "local user boosting a local article creates a public Announce activity" do
    assert_difference("Federails::Activity.where(action: 'Announce').count", 1) do
      @user.boost!(@local_article)
    end

    activity = Federails::Activity.where(action: "Announce").order(created_at: :desc).first

    assert_equal @user.federails_actor, activity.actor
    assert_equal @local_article, activity.entity
  end

  test "remote actor boost via inbound handler creates a Boost row and updates counters" do
    activity = {
      "id" => "https://remote.example/activities/announce-1",
      "type" => "Announce",
      "actor" => @remote_actor.federated_url,
      "object" => @local_post.federated_url
    }

    before_boostees = @remote_actor.reload.boostees_count

    assert_difference("Boost.count", 1) do
      Fediverse::Inbox::AnnounceHandler.handle_announce(activity)
    end

    assert_equal before_boostees + 1, @remote_actor.reload.boostees_count
    assert_equal 1, @local_post.reload.boosters_count
    assert Boost.exists?(actor: @remote_actor, boostable: @local_post)
  end

  test "inbound remote boost does not produce an outbound Announce activity" do
    activity = {
      "id" => "https://remote.example/activities/announce-2",
      "type" => "Announce",
      "actor" => @remote_actor.federated_url,
      "object" => @local_post.federated_url
    }

    assert_no_difference("Federails::Activity.where(action: 'Announce', actor: @remote_actor).count") do
      Fediverse::Inbox::AnnounceHandler.handle_announce(activity)
    end
  end

  test "Boost.boosted_ids_for accepts a User and returns matching boostable ids" do
    @user.boost!(@local_post)

    ids = Boost.boosted_ids_for(
      booster: @user,
      boostable_type: "Post",
      boostable_ids: [ @local_post.id ]
    )

    assert_equal [ @local_post.id ], ids
  end

  test "Boost.boosted_ids_for returns empty for nil booster" do
    assert_equal [], Boost.boosted_ids_for(booster: nil, boostable_type: "Post", boostable_ids: [ @local_post.id ])
  end

  test "User#boosts? reflects the underlying Boost row" do
    refute @user.boosts?(@local_post)
    @user.boost!(@local_post)

    assert @user.boosts?(@local_post)
    @user.unboost!(@local_post)

    refute @user.boosts?(@local_post)
  end

  test "duplicate boost by the same actor is rejected" do
    @user.boost!(@local_post)
    assert_no_difference("Boost.count") do
      @user.boost!(@local_post)
    end
  end

  test "boosting an article without a thumbnail enqueues ArticleThumbnailJob" do
    refute_predicate @local_article.thumbnail, :attached?

    assert_enqueued_with(job: ArticleThumbnailJob, args: [ @local_article.id ]) do
      @user.boost!(@local_article)
    end
  end

  test "boosting an article that already has a thumbnail does not enqueue ArticleThumbnailJob" do
    @local_article.thumbnail.attach(
      io: StringIO.new("thumbnail-bytes"),
      filename: "thumb.png",
      content_type: "image/png"
    )

    assert_no_enqueued_jobs(only: ArticleThumbnailJob) do
      @user.boost!(@local_article)
    end
  end

  test "boosting a post does not enqueue ArticleThumbnailJob" do
    assert_no_enqueued_jobs(only: ArticleThumbnailJob) do
      @user.boost!(@local_post)
    end
  end
end
