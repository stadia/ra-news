# frozen_string_literal: true

class Views::Posts::CreateTurboStream < Views::Base
  include Phlex::Rails::Helpers::TurboStream

  def initialize(post:)
    @post = post
  end

  def view_template
    if @post.persisted?
      if @post.parent_id.present?
        turbo_stream.append("replies_#{@post.parent_id}") do
          render Components::Posts::PostCard.new(post: @post, depth: 1)
        end
      else
        turbo_stream.prepend("posts_list") do
          render Components::Posts::PostCard.new(post: @post)
        end
      end

      turbo_stream.replace("post_form") do
        render Components::Posts::PostForm.new
      end
    else
      turbo_stream.replace("post_form") do
        render Components::Posts::PostForm.new(post: @post)
      end
    end
  end
end
