# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class ProfilesController < ApplicationController
  include Pagy::Method

  skip_before_action :authenticate_user!, only: [ :show, :posts, :comments, :blog, :boosts ]

  before_action :set_user
  before_action :require_own_profile, only: [ :likes, :followers, :following ]

  def show
    posts
  end

  def followers
    actor = @user.federails_actor
    @follow_actors = actor ? actor.following_followers.to_a : []
    render_activity_page(:followers)
  end

  def following
    actor = @user.federails_actor
    @follow_actors = actor ? actor.following_follows.to_a : []
    render_activity_page(:following)
  end

  def posts
    @pagy, @posts = pagy(
      @user.posts.standalone.visible
        .includes(:user, :federails_actor, :article, :tags)
        .order(created_at: :desc)
    )
    @liked_post_ids = liked_ids_for_posts(@posts)
    @boosted_post_ids = boosted_ids_for_posts(@posts)
    render_activity_page(:posts)
  end

  def comments
    @pagy, @posts = pagy(
      @user.posts.comments.kept
        .includes(:user, :federails_actor, :article, :tags)
        .order(created_at: :desc)
    )
    @liked_post_ids = liked_ids_for_posts(@posts)
    @boosted_post_ids = boosted_ids_for_posts(@posts)
    render_activity_page(:comments)
  end

  def likes
    @pagy, page_likes = pagy(Like.for_actor(@user.federails_actor))

    @likeables = Profiles::PolymorphicActivity.resolve(page_likes.pluck(:likeable_type, :likeable_id))
    render_activity_page(:likes)
  end

  def boosts
    @pagy, page_boosts = pagy(Boost.for_actor(@user.federails_actor))

    @boostables = Profiles::PolymorphicActivity.resolve(page_boosts.pluck(:boostable_type, :boostable_id))
    render_activity_page(:boosts)
  end

  def blog
    @pagy, @posts = pagy(
      @user.posts.published_blog.kept
        .includes(:user, :federails_actor, :article, :tags)
        .order(published_at: :desc)
    )
    @liked_post_ids = liked_ids_for_posts(@posts)
    @boosted_post_ids = boosted_ids_for_posts(@posts)
    render_activity_page(:blog)
  end

  private

    def set_user
      @user = User.find_by!(username: params[:username])
    end

    def render_activity_page(tab)
      if turbo_frame_request?
        render activity_list_component(tab)
      else
        render_show_with_activity(active_tab: tab)
      end
    end

    #: (Symbol) -> Views::Base
    def activity_list_component(tab)
      case tab
      when :posts, :comments, :blog
        Views::Profiles::ActivityList.new(
          **post_list_args,
          active_tab: tab
        )
      when :likes
        Views::Profiles::LikeList.new(user: @user, likeables: @likeables, pagy: @pagy)
      when :boosts
        Views::Profiles::BoostList.new(user: @user, boostables: @boostables, pagy: @pagy)
      when :followers
        Views::Profiles::FollowList.new(user: @user, followings: @follow_actors, type: :followers)
      when :following
        Views::Profiles::FollowList.new(user: @user, followings: @follow_actors, type: :following)
      else
        raise ArgumentError, "Unknown tab: #{tab}"
      end
    end

    # A record type, not `Hash[Symbol, untyped]`: this is double-splatted into
    # `Views::Profiles::ActivityList.new`, and Steep can only verify the
    # required keywords are supplied when the exact keys are declared.
    #: () -> { user: untyped, posts: untyped, pagy: untyped, liked_post_ids: untyped, boosted_post_ids: untyped }
    def post_list_args
      { user: @user, posts: @posts, pagy: @pagy,
        liked_post_ids: @liked_post_ids, boosted_post_ids: @boosted_post_ids }
    end

    def render_show_with_activity(active_tab:)
      actor = @user.federails_actor
      render Views::Profiles::Show.new(
        user: @user,
        actor: actor,
        followers_count: actor&.followers&.count || 0,
        following_count: actor&.follows&.count || 0,
        active_tab: active_tab,
        posts: @posts,
        likeables: @likeables,
        boostables: @boostables,
        pagy: @pagy,
        liked_post_ids: @liked_post_ids,
        boosted_post_ids: @boosted_post_ids,
        follow_actors: @follow_actors
      )
    end

    def require_own_profile
      unless current_user == @user
        redirect_to(user_profile_base_path(username: @user.username),
                    alert: "본인만 볼 수 있습니다")
      end
    end

    def liked_ids_for_posts(posts)
      Like.liked_ids_for(
        liker: current_user,
        likeable_type: "Post",
        likeable_ids: posts.map(&:id)
      )
    end

    def boosted_ids_for_posts(posts)
      Boost.boosted_ids_for(
        booster: current_user,
        boostable_type: "Post",
        boostable_ids: posts.map(&:id)
      )
    end
end
