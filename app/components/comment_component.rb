# frozen_string_literal: true

class CommentComponent < ViewComponent::Base
  def initialize(comment:, article:, depth: 0, children: {})
    @comment = comment
    @article = article
    @depth = depth
    @children = children
  end

  def wrapper_classes
    return "" if @depth.zero?

    "ml-8 mr-3 relative"
  end

  def render_children
    return "" if @children.empty?

    helpers.safe_join(@children.map do |child, grandchildren|
      render(CommentComponent.new(comment: child, article: @article, depth: @depth + 1, children: grandchildren))
    end)
  end

  def can_reply?
    @depth.zero?
  end
end
