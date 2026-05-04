# frozen_string_literal: true

class Components::Posts::PostThread < Components::Base
  def initialize(post:, liked: nil)
    @post = post
    @liked = liked
  end

  def view_template
    render Components::Posts::PostCard.new(post: @post, liked: @liked)

    div(id: "replies_#{@post.id}", class: "space-y-2") do
      @post.children.to_a.sort_by(&:created_at).each do |reply|
        render Components::Posts::PostCard.new(post: reply, depth: 1, show_actions: false)
      end
    end
  end
end
