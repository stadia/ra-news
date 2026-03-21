# frozen_string_literal: true

class Components::Posts::PostThread < Components::Base
  def initialize(post:)
    @post = post
  end

  def view_template
    render Components::Posts::PostCard.new(post: @post)

    div(id: "replies_#{@post.id}", class: "space-y-2") do
      @post.children.includes(:user, :federails_actor).order(:created_at).each do |reply|
        render Components::Posts::PostCard.new(post: reply, depth: 1)
      end
    end
  end
end
