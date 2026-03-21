# frozen_string_literal: true

require "test_helper"

class PostLikeFederationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @local_post = posts(:root_post)
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
  end

  test "local user like on remote post creates federated Like activity" do
    assert_difference("Federails::Activity.where(action: 'Like').count", 1) do
      @user.like!(@remote_post)
    end

    activity = Federails::Activity.where(action: "Like").order(created_at: :desc).first

    assert_equal @user.federails_actor, activity.actor
    assert_equal @remote_post, activity.entity
    assert_equal [ @remote_actor.federated_url ], activity.to
  end

  test "local user unlike on remote post creates federated Undo activity" do
    @user.like!(@remote_post)

    assert_difference("Federails::Activity.where(action: 'Undo').count", 1) do
      @user.unlike!(@remote_post)
    end

    undo_activity = Federails::Activity.where(action: "Undo").order(created_at: :desc).first

    assert_equal @user.federails_actor, undo_activity.actor
    assert_instance_of Federails::Activity, undo_activity.entity
    assert_equal "Like", undo_activity.entity.action
  end

  test "incoming remote like increases local post like count" do
    activity = {
      "id" => "https://remote.example/activities/like-1",
      "type" => "Like",
      "actor" => { "id" => @remote_actor.federated_url },
      "object" => {
        "id" => @local_post.federated_url,
        "type" => "Note"
      }
    }

    assert_difference("Like.count", 1) do
      ActivityPub::Handlers::PostLikeHandler.handle_like(activity)
    end

    assert @remote_actor.likes?(@local_post)
    assert_equal 1, @local_post.reload.likers_count
  end

  test "incoming undo like decreases local post like count" do
    @remote_actor.like!(@local_post)

    activity = {
      "id" => "https://remote.example/activities/undo-like-1",
      "type" => "Undo",
      "actor" => { "id" => @remote_actor.federated_url },
      "object" => {
        "id" => "https://remote.example/activities/like-1",
        "type" => "Like",
        "actor" => @remote_actor.federated_url,
        "object" => {
          "id" => @local_post.federated_url,
          "type" => "Note"
        }
      }
    }

    assert_difference("Like.count", -1) do
      ActivityPub::Handlers::PostLikeHandler.handle_undo_like(activity)
    end

    assert_not @remote_actor.likes?(@local_post)
    assert_equal 0, @local_post.reload.likers_count
  end
end
