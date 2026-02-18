# frozen_string_literal: true

class Components::Comments::Comments < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(article:, comments:)
    @article = article
    @comments = comments.to_a
    @comments_tree = build_tree(@comments)
  end

  def view_template
    turbo_frame_tag("comments") do
      div(class: "space-y-4", id: "comments_list") do
        if @comments.any?
          render_tree(@comments_tree)
        end
      end
    end
  end

  private

  def render_tree(tree, depth: 0)
    helpers.safe_join(tree.map do |comment, children|
      render(CommentComponent.new(comment:, article: @article, depth:, children:))
    end)
  end

  def build_tree(comments)
    grouped = comments.group_by(&:parent_id)
    build_subtree(grouped, nil)
  end

  def build_subtree(grouped, parent_id)
    nodes = grouped[parent_id] || []
    sorted_nodes = nodes.sort_by(&:created_at).tap { |s| s.reverse! if parent_id.nil? }
    sorted_nodes.each_with_object({}) do |comment, tree|
      tree[comment] = build_subtree(grouped, comment.id)
    end
  end
end
