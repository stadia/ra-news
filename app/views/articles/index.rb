# frozen_string_literal: true

class Views::Articles::Index < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def initialize(pagy:, articles:, search: nil)
    @pagy = pagy
    @articles = articles
    @search = search
  end

  def view_template
    content_for :title, "지난 글 모음 | Ruby-News"

    div(class: "text-center mb-8 lg:mb-12") do
      render RubyUI::Heading.new(level: 1, class: "font-bold text-content mb-4") { "지난 글들" }
      p(class: "text-lg text-content-secondary max-w-2xl mx-auto") do
        plain "#{@pagy.count}개의 글이 있습니다"
        plain @search.to_s if @search.present?
      end
    end

    div(id: "articlesList", class: "space-y-6 lg:space-y-8 max-w-6xl mx-auto") do
      @articles.each do |article|
        render Components::Articles::Article.new(article: article)
      end

      render Components::Pagination.new(pagy: @pagy)
    end
  end
end
