# frozen_string_literal: true
# rbs_inline: enabled

class ProfilesController < ApplicationController
  include Pagy::Method

  skip_before_action :authenticate_user!, only: [ :show, :posts, :comments ]

  before_action :set_user
  before_action :require_own_profile, only: [ :followers, :following ]

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
      @user.posts.standalone
        .includes(:user, :federails_actor, :article, :tags)
        .order(created_at: :desc)
    )
    @liked_post_ids = liked_ids_for_posts(@posts)
    @boosted_post_ids = boosted_ids_for_posts(@posts)
    render_activity_page(:posts)
  end

  def comments
    @pagy, @posts = pagy(
      @user.posts.comments
        .includes(:user, :federails_actor, :article, :tags)
        .order(created_at: :desc)
    )
    @liked_post_ids = liked_ids_for_posts(@posts)
    @boosted_post_ids = boosted_ids_for_posts(@posts)
    render_activity_page(:comments)
  end

  def likes
    unless current_user == @user
      redirect_to(user_profile_base_path(username: @user.username),
                  alert: "본인만 볼 수 있습니다") and return
    end

    likes = Like.where(actor: @user.federails_actor, likeable_type: %w[Article Post])
                .order(created_at: :desc)
    @pagy, page_likes = pagy(likes)

    article_ids = page_likes.select { |l| l.likeable_type == "Article" }.map(&:likeable_id)
    post_ids = page_likes.select { |l| l.likeable_type == "Post" }.map(&:likeable_id)

    articles_by_id = Article.kept.where(id: article_ids)
                            .includes(:user, :site, :tags).index_by(&:id)
    posts_by_id = Post.where(id: post_ids)
                      .includes(:user, :federails_actor, :article, :tags).index_by(&:id)

    @likeables = page_likes.map { |l|
      l.likeable_type == "Article" ? articles_by_id[l.likeable_id] : posts_by_id[l.likeable_id]
    }.compact
    render_activity_page(:likes)
  end

  def boosts
    unless current_user == @user
      redirect_to(user_profile_base_path(username: @user.username),
                  alert: "본인만 볼 수 있습니다") and return
    end

    boosts = Boost.where(actor: @user.federails_actor, boostable_type: %w[Article Post])
                  .order(created_at: :desc)
    @pagy, page_boosts = pagy(boosts)

    article_ids = page_boosts.select { |b| b.boostable_type == "Article" }.map(&:boostable_id)
    post_ids = page_boosts.select { |b| b.boostable_type == "Post" }.map(&:boostable_id)

    articles_by_id = Article.kept.where(id: article_ids)
                            .includes(:user, :site, :tags).index_by(&:id)
    posts_by_id = Post.where(id: post_ids)
                      .includes(:user, :federails_actor, :article, :tags).index_by(&:id)

    @boostables = page_boosts.map { |b|
      b.boostable_type == "Article" ? articles_by_id[b.boostable_id] : posts_by_id[b.boostable_id]
    }.compact
    render_activity_page(:boosts)
  end

  private

    def set_user
      @user = User.find_by!(username: params[:username])
    end

    def render_activity_page(tab)
      case tab
      when :posts
        if turbo_frame_request?
          render Views::Profiles::PostList.new(
            user: @user, posts: @posts, pagy: @pagy,
            liked_post_ids: @liked_post_ids,
            boosted_post_ids: @boosted_post_ids
          )
        else
          render_show_with_activity(active_tab: :posts)
        end
      when :comments
        if turbo_frame_request?
          render Views::Profiles::CommentList.new(
            user: @user, posts: @posts, pagy: @pagy,
            liked_post_ids: @liked_post_ids,
            boosted_post_ids: @boosted_post_ids
          )
        else
          render_show_with_activity(active_tab: :comments)
        end
      when :likes
        if turbo_frame_request?
          render Views::Profiles::LikeList.new(
            user: @user, likeables: @likeables, pagy: @pagy
          )
        else
          render_show_with_activity(active_tab: :likes)
        end
      when :boosts
        if turbo_frame_request?
          render Views::Profiles::BoostList.new(
            user: @user, boostables: @boostables, pagy: @pagy
          )
        else
          render_show_with_activity(active_tab: :boosts)
        end
      when :followers, :following
        if turbo_frame_request?
          render Views::Profiles::FollowList.new(
            user: @user, followings: @follow_actors, type: tab
          )
        else
          render_show_with_activity(active_tab: tab)
        end
      end
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
