# frozen_string_literal: true

class Views::Activities::Feed < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def initialize(posts:)
    @posts = posts.to_a
    @posts_tree = build_tree(@posts)
  end

  def view_template
    content_for :title, "피드 | Ruby-News"

    div(class: "text-center mb-8 lg:mb-12") do
      render RubyUI::Heading.new(level: 1, class: "font-bold text-content mb-4") { "피드" }
    end

    div(id: "postsList", class: "space-y-6 lg:space-y-8 max-w-6xl mx-auto") do
      if @posts.empty?
        render_empty_state
      else
        render_tree(@posts_tree)
      end
    end
  end

  private

  def render_tree(tree, depth: 0)
    tree.each do |post, children|
      render_post(post, depth:)
      render_tree(children, depth: depth + 1) if children.any?
    end
  end

  def render_empty_state
    render RubyUI::Card.new(class: "bg-surface border-border-muted shadow-lg") do
      render RubyUI::CardContent.new(class: "p-6 text-content-secondary text-center") do
        plain "표시할 포스트가 없습니다."
      end
    end
  end

  def render_post(post, depth: 0)
    author_name = post.user&.name || post.federails_actor&.name || "알 수 없음"
    indent_class = depth.zero? ? "" : "ml-4 sm:ml-8"

    div(class: "#{indent_class} #{'border-l border-border-muted pl-4 sm:pl-6' if depth.positive?}".strip) do
      render RubyUI::Card.new(class: "bg-surface border-border-muted shadow-sm") do
      render RubyUI::CardContent.new(class: "p-5 space-y-3") do
        div(class: "flex items-center justify-between gap-3 text-sm") do
          span(class: "font-semibold text-content") { author_name }
          time(class: "text-content-secondary", datetime: post.created_at.iso8601) do
            plain I18n.l(post.created_at, format: :short)
          end
        end

        p(class: "text-content leading-relaxed wrap-break-word whitespace-pre-wrap") do
          plain post.body
        end
      end
      end
    end
  end

  def build_tree(posts)
    posts_by_id = posts.index_by(&:id)
    grouped = posts.group_by do |post|
      posts_by_id.key?(post.parent_id) ? post.parent_id : nil
    end

    build_subtree(grouped, nil)
  end

  def build_subtree(grouped, parent_id)
    nodes = grouped[parent_id] || []
    sorted_nodes = if parent_id.nil?
      nodes.sort_by(&:created_at).reverse
    else
      nodes.sort_by(&:created_at)
    end

    sorted_nodes.each_with_object({}) do |post, tree|
      tree[post] = build_subtree(grouped, post.id)
    end
  end
end
