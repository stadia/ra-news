# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Feeds
  # 홈 피드(팔로잉 + 로컬 + 본인 + 부스트된 포스트)의 조회 로직.
  # 웹(FeedController)과 API(Api::V1::FeedController)가 같은 타임라인을 보도록
  # 컨트롤러 바깥으로 뽑았다. 페이지네이션은 호출부(pagy)가 담당한다.
  module Timeline
    INCLUDES = [ :user, :federails_actor, :article, :tags, { parent: [ :user, :federails_actor ] } ].freeze

    class << self
      #: (User user) -> ActiveRecord::Relation
      def posts_for(user)
        actor = user.federails_actor
        return Post.none if actor.nil?

        following_ids = following_actor_ids(actor)

        Post
          .includes(*INCLUDES)
          .where(federails_actor_id: following_ids)
          .or(Post.where(federails_actor_id: Federails::Actor.local.select(:id)))
          .or(Post.where(user_id: user.id))
          .or(Post.where(id: boosted_post_ids(actor, following_ids)))
          .visible
          .order(created_at: :desc)
      end

      # 팔로우 중인(또는 본인) 액터의 부스트 때문에 피드에 올라온 포스트만
      # { post_id => Federails::Actor } 로 돌려준다. 본인 글, 팔로잉 액터의 글,
      # 로컬 액터의 글은 부스트가 없어도 노출되므로 귀속 대상에서 제외한다.
      #: (posts: untyped, user: User) -> Hash[Integer, Federails::Actor]
      def boosters_for(posts:, user:)
        actor = user.federails_actor
        return {} if posts.blank? || actor.nil?

        candidate_actor_ids = following_actor_ids(actor).to_a + [ actor.id ]

        attribution_post_ids = posts.reject { |post|
          post.user_id == user.id ||
            post.federails_actor&.local? ||
            (post.federails_actor_id.present? && candidate_actor_ids.include?(post.federails_actor_id))
        }.map(&:id)

        return {} if attribution_post_ids.empty?

        Boost
          .where(boostable_type: "Post", boostable_id: attribution_post_ids, actor_id: candidate_actor_ids)
          .order(created_at: :desc)
          .includes(:actor)
          .each_with_object({}) do |boost, memo|
            memo[boost.boostable_id] ||= boost.actor
          end
      end

      private

      def following_actor_ids(actor)
        Federails::Following.accepted.where(actor: actor).select(:target_actor_id)
      end

      def boosted_post_ids(actor, following_ids)
        Boost
          .where(boostable_type: "Post", actor_id: following_ids)
          .or(Boost.where(boostable_type: "Post", actor_id: actor.id))
          .select(:boostable_id)
      end
    end
  end
end
