# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :require_authentication, only: [ :create ]

  def create
    @post = Current.user.posts.build(post_params)

    respond_to do |format|
      if @post.save
        format.turbo_stream { render turbo_stream: turbo_stream.append("posts_list", "") }
        format.html { redirect_to feed_path }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.append("posts_list", ""), status: :unprocessable_entity }
        format.html { redirect_to feed_path, alert: "포스트 작성에 실패했습니다." }
      end
    end
  end

  private

  def post_params
    params.expect(post: [ :body, :parent_id ])
  end
end
