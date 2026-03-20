# frozen_string_literal: true

class Views::Activities::Feed < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def initialize(posts:)
    @posts = posts
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
        @posts.each do |post|
          render_post(post)
        end
      end
    end
  end

  private

  def render_empty_state
    render RubyUI::Card.new(class: "bg-surface border-border-muted shadow-lg") do
      render RubyUI::CardContent.new(class: "p-6 text-content-secondary text-center") do
        plain "표시할 포스트가 없습니다."
      end
    end
  end

  def render_post(post)
    author_name = post.user&.name || post.federails_actor&.name || "알 수 없음"

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
