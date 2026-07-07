# frozen_string_literal: true
# rbs_inline: enabled

class BlogsController < ApplicationController
  include PostViewing

  skip_before_action :authenticate_user!, only: [ :show ]

  # GET /@:username/blog/:slug — public blog detail. Scopes by username so the
  # URL is canonical, but slugs are globally unique so this never ambiguates.
  def show
    post = User.find_by!(username: params[:username])
               .posts.blog.includes(POST_SHOW_INCLUDES)
               .find_by!(slug: params[:slug])
    render_post_show(post)
  end
end
