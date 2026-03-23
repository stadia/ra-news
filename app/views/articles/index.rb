# frozen_string_literal: true

class Views::Articles::Index < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def initialize(pagy:, articles:, sidebar_tags:, search: nil, liked_article_ids: [])
    @pagy = pagy
    @articles = articles
    @sidebar_tags = sidebar_tags
    @search = search
    @liked_article_ids = liked_article_ids
  end

  def view_template
    content_for :title, "지난 글 모음 | Ruby-News"

    div(class: "flex flex-col lg:flex-row gap-6") do
      div(class: "flex-1 min-w-0") do
        div(class: "mb-8") do
          render RubyUI::Heading.new(level: 1, class: "font-bold text-content mb-4") { "지난 글들" }
          p(class: "text-lg text-content-secondary") do
            plain "#{@pagy.count}개의 글이 있습니다"
            plain " #{@search}" if @search.present?
          end
        end

        div(id: "articlesList", class: "space-y-6 lg:space-y-8") do
          @articles.each do |article|
            render Components::Articles::Article.new(article: article, liked: @liked_article_ids.include?(article.id))
          end

          render Components::Pagination.new(pagy: @pagy)
        end
      end

      div(class: "w-full lg:w-72 shrink-0 order-last lg:order-0") do
        render Components::TagsSidebar.new(tags: @sidebar_tags)
      end
    end
  end
end
