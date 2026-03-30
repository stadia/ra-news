# frozen_string_literal: true

class Components::Articles::Article < Components::Base
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  attr_reader :article

  def initialize(article:, liked: nil)
    @article = article
    @liked = liked
  end

  def view_template
    render RubyUI::Card.new(id: (dom_id article), class:
        "bg-surface shadow-md hover:shadow-lg transition-shadow overflow-hidden border-border-strong p-3 md:p-6 flex flex-col"
    ) do
      header_section
      div(class: "mb-4") { article.url }
      summary_section
      footer_section
    end
  end

  private

  def header_section
    display_title = @article.title_ko || @article.title
    div(class: "mb-3") do
      h2(class: "text-xl font-semibold text-content hover:text-link-hover") do
        link_to display_title, article_path(article)
      end
      if @article.title_ko.present? && @article.title_ko != @article.title
        h3(class: "text-l text-content wrap-break-word") { article.title }
      end
    end
  end

  def summary_section
    div(class: "text-content-secondary mb-4 text-sm leading-relaxed grow") do
      summary = @article.summary_key
      if summary.present?
        if summary.is_a?(Array)
          ul(class: "list-disc pl-5 space-y-1") do
            summary.each do |item|
              li { item }
            end
          end
        elsif summary.is_a?(String)
          p { summary }
        end
      end
    end
  end

  def footer_section
    render RubyUI::Separator.new(class: "mt-auto")
    div(class: "pt-4 flex flex-wrap justify-between items-center text-xs text-content-muted gap-y-2") do
      span(class: "inline-flex items-center") do
        Hero::User(variant: :outline, class: "w-4 h-4 mr-1 text-content-muted")
        render Components::Articles::ArticleUser.new(article: @article)
      end
      render Components::Likes::Button.new(likeable: @article, liked: @liked)
      span(class: "inline-flex items-center") do
        Hero::ChatBubbleLeftEllipsis(variant: :outline, class: "w-4 h-4 mr-1 text-content-muted")
        plain @article.posts_count.to_s
      end
      span(class: "inline-flex items-center") do
        Hero::CalendarDays(variant: :outline, class: "w-4 h-4 mr-1 text-content-muted")
        plain(@article.published_at&.strftime("%Y년 %m월 %d일") || "N/A")
      end
    end
  end
end
