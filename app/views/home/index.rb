# frozen_string_literal: true

class Views::Home::Index < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo

  def initialize(articles:, recent_comments:, sidebar_tags:, liked_article_ids: [], featured_articles: [])
    @articles = articles
    @featured_articles = featured_articles
    @recent_comments = recent_comments
    @sidebar_tags = sidebar_tags
    @liked_article_ids = liked_article_ids
  end

  def view_template
    content_for :title, "Ruby-News | 루비·Rails 개발자를 위한 AI 뉴스"

    div(class: "flex flex-col lg:flex-row gap-6") do
      div(class: "flex-1 min-w-0") do
        if @featured_articles.any?
          render Components::Home::Feature.new(
            articles: @featured_articles,
            liked_article_ids: @liked_article_ids
          )
        end

        div(class: "lg:hidden mb-6") do
          render Components::TagsSidebar.new(tags: @sidebar_tags)
        end

        section do
          div(class: "flex items-center mb-4") do
            h2(class: "text-2xl font-bold text-content") { "최신 뉴스" }
          end

          div(id: "articlesList", class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6") do
            @articles.each do |article|
              render Components::Home::Article.new(article: article, liked: @liked_article_ids.include?(article.id))
            end
          end
        end

        if @articles.any?
          div(class: "mt-8 flex justify-center") do
            link_to(
              articles_path,
              class: "inline-flex items-center gap-1 px-5 py-2.5 rounded-md border border-border-strong bg-surface text-content hover:bg-surface-muted hover:text-link-hover transition-colors duration-200 text-sm font-medium"
            ) do
              plain "지난 글 더 보기"
              span(class: "ml-1") { "→" }
            end
          end
        end
      end

      div(class: "w-full lg:w-72 shrink-0 order-last lg:order-0") do
        div(class: "space-y-6") do
          render Components::RecentCommentsSidebar.new(recent_comments: @recent_comments)
          div(class: "hidden lg:block") do
            render Components::TagsSidebar.new(tags: @sidebar_tags)
          end
        end
      end
    end
  end
end
