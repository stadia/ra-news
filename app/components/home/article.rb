# frozen_string_literal: true

class Components::Home::Article < Components::Base
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  attr_reader :article

  def initialize(article:)
    @article = article
  end

  def view_template
    render RubyUI::Card.new(id: dom_id(article), class: "bg-gray-800 border-gray-600 hover:border-gray-500 shadow-lg hover:shadow-xl transition-all duration-300 p-6 flex flex-col") do
      header_section
      render RubyUI::Badge.new(variant: :blue, size: :sm, class: "mb-4 self-start") { article.host }
      summary_section
      footer_section
    end
  end

  private

  def header_section
    display_title = article.title_ko || article.title
    div(class: "mb-4") do
      h2(class: "text-xl font-bold text-white mb-2 leading-tight hover:text-green-400 transition-colors duration-200") do
        link_to(display_title, article_path(article))
      end
      if article.title_ko.present? && article.title_ko != article.title
        h3(class: "text-lg font-medium text-gray-200") { article.title }
      end
    end
  end

  def summary_section
    div(class: "text-gray-200 mb-6 text-base leading-relaxed grow space-y-2") do
      summary = article.summary_key
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
    div(class: "mt-auto pt-4 flex flex-wrap justify-between items-center text-sm text-gray-300 border-t border-gray-600 gap-y-2") do
      span(class: "inline-flex items-center") do
        Hero::User(variant: :outline, class: "w-4 h-4 mr-1 text-gray-500")
        render Components::Articles::ArticleUser.new(article: article)
      end
      span(class: "inline-flex items-center") do
        Hero::ChatBubbleLeftEllipsis(variant: :outline, class: "w-4 h-4 mr-1 text-gray-500")
        plain article.comments_count.to_s
      end
      span(class: "inline-flex items-center") do
        Hero::CalendarDays(variant: :outline, class: "w-4 h-4 mr-1 text-gray-500")
        plain(article.published_at&.strftime("%Y년 %m월 %d일") || "N/A")
      end
    end
  end
end
