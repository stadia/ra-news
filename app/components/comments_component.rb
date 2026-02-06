# frozen_string_literal: true

class CommentsComponent < ViewComponent::Base
  def initialize(article:, comments:)
    @article = article
    @comments = comments.to_a
    @comments_tree = build_tree(@comments)
  end

  def render_tree(tree, depth: 0)
    helpers.safe_join(tree.map do |comment, children|
      render(CommentComponent.new(comment:, article: @article, depth:, children:))
    end)
  end

  private

  def build_tree(comments)
    grouped = comments.group_by(&:parent_id)
    build_subtree(grouped, nil)
  end

  def build_subtree(grouped, parent_id)
    nodes = grouped[parent_id] || []
    sorted_nodes = parent_id.nil? ? nodes.sort_by(&:created_at).reverse : nodes.sort_by(&:created_at)
    sorted_nodes.each_with_object({}) do |comment, tree|
      tree[comment] = build_subtree(grouped, comment.id)
    end
  end
end
