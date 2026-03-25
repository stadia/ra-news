# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :authenticate_user!, only: [ :create ]

  def create
    @post = current_user.posts.build(post_params)

    respond_to do |format|
      if @post.save
        format.turbo_stream { render Views::Posts::CreateTurboStream.new(post: @post) }
        format.html { redirect_to feed_path }
      else
        format.turbo_stream { render Views::Posts::CreateTurboStream.new(post: @post), status: :unprocessable_entity }
        format.html { redirect_to feed_path, alert: "포스트 작성에 실패했습니다." }
      end
    end
  end

  private

  def post_params
    params.expect(post: [ :body, :parent_id ])
  end
end
