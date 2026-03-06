# frozen_string_literal: true

class Views::Home::Index < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def initialize(articles:, recent_comments:)
    @articles = articles
    @recent_comments = recent_comments
  end

  def view_template
    content_for :title, "Ruby-News | 루비·Rails 개발자를 위한 AI 뉴스"

    div(class: "flex flex-col lg:flex-row gap-6") do
      div(class: "flex-1 min-w-0") do
        div(id: "articlesList", class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6") do
          @articles.each do |article|
            render Components::Home::Article.new(article: article)
          end
        end
      end

      div(class: "w-full lg:w-72 shrink-0 order-last lg:order-0") do
        render Components::RecentCommentsSidebar.new(recent_comments: @recent_comments)
      end
    end
  end
end
