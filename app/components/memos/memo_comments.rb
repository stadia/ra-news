# frozen_string_literal: true

class Components::Memos::MemoComments < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(memo:, comments:)
    @memo = memo
    @comments = comments.to_a
    @comments_tree = build_tree(@comments)
  end

  def view_template
    turbo_frame_tag("comments") do
      div(class: "space-y-4", id: "comments_list") do
        render_tree(@comments_tree) if @comments.any?
      end
    end
  end

  private

  def render_tree(tree, depth: 0)
    view_context.safe_join(tree.map do |comment, children|
      render(Components::Memos::MemoComment.new(comment:, memo: @memo, depth:, children:))
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
