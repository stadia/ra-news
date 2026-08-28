# frozen_string_literal: true

require "test_helper"

class Feeds::TimelineTest < ActiveSupport::TestCase
  setup do
    @john = users(:john)
    @john_actor = fedipub_actors(:john_actor)
    @jane_actor = fedipub_actors(:jane_actor)

    assert Fedipub::Following.accepted.exists?(actor: @john_actor, target_actor: @jane_actor),
      "test premise: john은 jane을 팔로우해야 한다"

    @stranger = Fedipub::Actor.create!(
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

    # jane_actor는 local이라 `local?` 분기에 먼저 걸려 `include?` 분기를
    # 검증하지 못한다. 원격 팔로잉이 있어야 그 분기가 실제로 평가된다.
    @followed_remote = Fedipub::Actor.create!(
      federated_url: "https://remote.example/users/followed",
      username: "followed",
      name: "Followed Remote",
      server: "remote.example",
      inbox_url: "https://remote.example/users/followed/inbox",
      outbox_url: "https://remote.example/users/followed/outbox",
      followers_url: "https://remote.example/users/followed/followers",
      followings_url: "https://remote.example/users/followed/following",
      profile_url: "https://remote.example/@followed",
      actor_type: "Person",
      local: false
    )
    Fedipub::Following.create!(actor: @john_actor, target_actor: @followed_remote, status: "accepted")
  end

  # 팔로우 대상 actor id를 값 배열로 다루지 않으면 (relation에 to_a를 부르면)
  # `where(actor_id:)`가 기본키 nil로 캐스팅돼 `actor_id IS NULL`이 되고,
  # 팔로우한 사람의 부스트는 영영 귀속되지 않는다.
  test "팔로우한 액터의 부스트가 귀속된다" do
    post = Post.create!(
      body: "stranger post boosted by jane",
      fedipub_actor: @stranger,
      federated_url: "https://remote.example/notes/boosted"
    )
    Boost.create!(actor: @jane_actor, boostable: post)

    boosters = Feeds::Timeline.boosters_for(posts: [ post ], user: @john)

    assert_equal({ post.id => @jane_actor }, boosters)
  end

  # 반대편: `include?` 비교가 항상 거짓이면 팔로잉 액터의 글까지 귀속 대상에
  # 들어가, 팔로우 때문에 뜬 글이 "누가 부스트함"으로 잘못 표시된다.
  test "팔로우한 원격 액터가 쓴 글은 본인이 부스트했어도 귀속하지 않는다" do
    post = Post.create!(
      body: "followed remote post",
      fedipub_actor: @followed_remote,
      federated_url: "https://remote.example/notes/followed-own"
    )
    Boost.create!(actor: @john_actor, boostable: post)

    boosters = Feeds::Timeline.boosters_for(posts: [ post ], user: @john)

    assert_empty boosters
  end

  test "본인이 쓴 글은 귀속하지 않는다" do
    post = Post.create!(body: "john's own post", user: @john, fedipub_actor: @john_actor)
    Boost.create!(actor: @john_actor, boostable: post)

    assert_empty Feeds::Timeline.boosters_for(posts: [ post ], user: @john)
  end

  test "로컬 액터의 글은 팔로우하지 않아도 뜨므로 귀속하지 않는다" do
    admin_actor = fedipub_actors(:admin_actor)
    post = Post.create!(body: "admin local post", user: users(:admin), fedipub_actor: admin_actor)
    Boost.create!(actor: @jane_actor, boostable: post)

    assert_empty Feeds::Timeline.boosters_for(posts: [ post ], user: @john)
  end

  test "팔로우하지 않은 액터의 부스트는 귀속하지 않는다" do
    post = Post.create!(
      body: "stranger post boosted by stranger",
      fedipub_actor: @stranger,
      federated_url: "https://remote.example/notes/self-boosted"
    )
    Boost.create!(actor: @stranger, boostable: post)

    assert_empty Feeds::Timeline.boosters_for(posts: [ post ], user: @john)
  end

  test "피드는 팔로우한 액터가 부스트한 글을 포함한다" do
    post = Post.create!(
      body: "boost-only visible post",
      fedipub_actor: @stranger,
      federated_url: "https://remote.example/notes/boost-only"
    )
    Boost.create!(actor: @jane_actor, boostable: post)

    assert_includes Feeds::Timeline.posts_for(@john), post
  end
end
