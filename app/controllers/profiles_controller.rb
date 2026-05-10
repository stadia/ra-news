# frozen_string_literal: true
# rbs_inline: enabled

class ProfilesController < ApplicationController
  include Pagy::Method

  skip_before_action :authenticate_user!, except: [ :likes ]

  before_action :set_user

  def show
    posts
  end

  def followers
    actor = @user.federails_actor
    followings = actor ? actor.following_followers.to_a : []
    render_follow_page(actor, followings, :followers)
  end

  def following
    actor = @user.federails_actor
    followings = actor ? actor.following_follows.to_a : []
    render_follow_page(actor, followings, :following)
  end

  def posts
    @pagy, @posts = pagy(
      @user.posts.standalone
        .includes(:user, :federails_actor, :article, :tags)
        .order(created_at: :desc)
    )
    @liked_post_ids = liked_ids_for_posts(@posts)
    render_activity_page(:posts)
  end

  def comments
    @pagy, @posts = pagy(
      @user.posts.comments
        .includes(:user, :federails_actor, :article, :tags)
        .order(created_at: :desc)
    )
    render_activity_page(:comments)
  end

  def likes
    unless current_user == @user
      redirect_to(user_profile_path(username: @user.username),
                  alert: "본인만 볼 수 있습니다") and return
    end

    likes = Like.where(liker: @user, likeable_type: %w[Article Post])
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

  private

    def set_user
      @user = User.find_by!(username: params[:username])
    end

    def render_follow_page(actor, followings, type)
      if turbo_frame_request?
        render Views::Profiles::FollowList.new(user: @user, followings: followings, type: type)
      else
        render Views::Profiles::Show.new(
          user: @user,
          actor: actor,
          followers_count: actor&.followers&.count || 0,
          following_count: actor&.follows&.count || 0,
          follow_actors: followings,
          follow_type: type
        )
      end
    end

    def render_activity_page(tab)
      case tab
      when :posts
        if turbo_frame_request?
          render Views::Profiles::PostList.new(
            user: @user, posts: @posts, pagy: @pagy,
            liked_post_ids: @liked_post_ids
          )
        else
          render_show_with_activity(active_tab: :posts)
        end
      when :comments
        if turbo_frame_request?
          render Views::Profiles::CommentList.new(
            user: @user, posts: @posts, pagy: @pagy
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
        pagy: @pagy,
        liked_post_ids: @liked_post_ids
      )
    end

    def liked_ids_for_posts(posts)
      Like.liked_ids_for(
        liker: current_user,
        likeable_type: "Post",
        likeable_ids: posts.map(&:id)
      )
    end
end
