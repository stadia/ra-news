# frozen_string_literal: true

class Views::Posts::CreateTurboStream < Views::Base
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::TurboStream

  def initialize(post:)
    @post = post
  end

  def view_template
    if @post.persisted?
      if @post.parent_id.present?
        parent_post = @post.parent.reload

        turbo_stream.replace(dom_id(parent_post)) do
          render Components::Posts::PostCard.new(post: parent_post)
        end

        turbo_stream.prepend("posts_list") do
          render Components::Posts::PostCard.new(post: @post)
        end
      else
        turbo_stream.prepend("posts_list") do
          render Components::Posts::PostThread.new(post: @post)
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
