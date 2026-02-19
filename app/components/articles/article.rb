# frozen_string_literal: true

class Components::Articles::Article < Components::Base
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  def initialize(article:)
    @article = article
  end

  def view_template
    div(id: dom_id(@article), class: "bg-gray-800 rounded-xl border border-gray-600 hover:border-gray-500 shadow-lg hover:shadow-xl transition-all duration-300 p-6 flex flex-col") do
      header_section
      source_link_section
      summary_section
      footer_section
    end
  end

  private

  def header_section
    display_title = @article.title_ko || @article.title
    div(class: "mb-4") do
      h2(class: "text-xl font-bold text-white mb-2 leading-tight hover:text-green-400 transition-colors duration-200") do
        link_to(display_title, helpers.article_path(@article.slug))
      end
      if @article.title_ko.present? && @article.title_ko != @article.title
        h3(class: "text-lg font-medium text-gray-200") { @article.title }
      end
    end
  end

  def source_link_section
    div(class: "mb-4") do
      if (url = safe_url(@article.url))
        link_to(url, target: "_blank", rel: "noopener noreferrer", class: "inline-flex items-center text-sm text-blue-300 hover:text-blue-200 hover:underline font-medium") do
          plain @article.host
          Hero::ArrowTopRightOnSquare(variant: :outline, class: "w-4 h-4 ml-1")
        end
      else
        span(class: "inline-flex items-center text-sm text-gray-500") do
          plain @article.host
        end
      end
    end
  end

  def summary_section
    div(class: "text-gray-200 mb-6 text-base leading-relaxed grow space-y-2") do
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
    div(class: "mt-auto pt-4 flex flex-wrap justify-between items-center text-sm text-gray-300 border-t border-gray-600 gap-y-2") do
      span(class: "inline-flex items-center") do
        Hero::User(variant: :outline, class: "w-4 h-4 mr-1 text-gray-500")
        render Components::Articles::ArticleUser.new(article: @article)
      end
      span(class: "inline-flex items-center") do
        Hero::ChatBubbleLeftEllipsis(variant: :outline, class: "w-4 h-4 mr-1 text-gray-500")
        plain @article.comments_count.to_s
      end
      span(class: "inline-flex items-center") do
        Hero::CalendarDays(variant: :outline, class: "w-4 h-4 mr-1 text-gray-500")
        plain(@article.published_at&.strftime("%Y년 %m월 %d일") || "N/A")
      end
    end
  end
end
