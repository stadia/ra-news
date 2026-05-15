# frozen_string_literal: true

class Components::Home::Feature < Components::Base
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ImageTag
  include PhlexIcons

  def initialize(articles:, liked_article_ids: [])
    @articles = articles
    @liked_article_ids = liked_article_ids
  end

  def view_template
    return if @articles.empty?

    hero, *rest = @articles

    section(class: "mb-8") do
      div(class: "flex items-center mb-4") do
        h2(class: "text-2xl font-bold text-content") { "주요 뉴스" }
      end

      div(class: "grid grid-cols-1 lg:grid-cols-3 gap-6") do
        div(class: "lg:col-span-2") { hero_card(hero) }

        if rest.any?
          div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-1 gap-6") do
            rest.each { |article| small_card(article) }
          end
        end
      end
    end
  end

  private

  def hero_card(article)
    render RubyUI::Card.new(
      id: dom_id(article, :feature),
      class: "bg-surface border-border-muted hover:border-border-strong shadow-lg hover:shadow-xl transition-all duration-300 overflow-hidden flex flex-col h-full"
    ) do
      thumbnail(article, size: [ 1200, 675 ], aspect: "aspect-video")
      div(class: "p-6 flex flex-col flex-1") do
        title_block(article, size: :large)
        render RubyUI::Badge.new(variant: :blue, size: :sm, class: "mb-4 self-start") { article.host }
        summary_block(article) if article.summary_key.present?
        meta_block(article)
      end
    end
  end

  def small_card(article)
    render RubyUI::Card.new(
      id: dom_id(article, :feature),
      class: "bg-surface border-border-muted hover:border-border-strong shadow-md hover:shadow-lg transition-all duration-300 overflow-hidden flex flex-col h-full"
    ) do
      thumbnail(article, size: [ 600, 338 ], aspect: "aspect-video")
      div(class: "p-4 flex flex-col flex-1") do
        title_block(article, size: :small)
        render RubyUI::Badge.new(variant: :blue, size: :sm, class: "mb-3 self-start") { article.host }
        meta_block(article)
      end
    end
  end

  def thumbnail(article, size:, aspect:)
    return unless article.thumbnail.attached?

    link_to(article_path(article), class: "block overflow-hidden") do
      image_tag(
        article.thumbnail.variant(resize_to_fill: size),
        class: "w-full #{aspect} object-cover hover:scale-105 transition-transform duration-300",
        loading: "lazy",
        decoding: "async",
        alt: article.title_ko || article.title
      )
    end
  end

  def title_block(article, size:)
    display_title = article.title_ko || article.title
    heading_class = size == :large ? "text-2xl font-bold mb-2 leading-tight" : "text-lg font-bold mb-2 leading-snug"

    div(class: "mb-3") do
      h3(class: "#{heading_class} text-content hover:text-link-hover transition-colors duration-200") do
        link_to(display_title, article_path(article))
      end
      if size == :large && article.title_ko.present? && article.title_ko != article.title
        p(class: "text-base text-content-secondary wrap-break-word") { article.title }
      end
    end
  end

  def summary_block(article)
    summary = article.summary_key
    div(class: "text-content-secondary mb-4 text-base leading-relaxed grow space-y-2") do
      case summary
      when Array
        ul(class: "list-disc pl-5 space-y-1") do
          summary.each { |item| li { item } }
        end
      when String
        p { summary }
      end
    end
  end

  def meta_block(article)
    render RubyUI::Separator.new(class: "mt-auto")
    div(class: "pt-3 flex flex-wrap justify-between items-center text-sm text-content-secondary gap-y-2") do
      span(class: "inline-flex items-center") do
        Hero::User(variant: :outline, class: "w-4 h-4 mr-1 text-content-muted")
        render Components::Articles::ArticleUser.new(article: article)
      end
      render Components::Likes::Button.new(likeable: article, liked: @liked_article_ids.include?(article.id))
      span(class: "inline-flex items-center") do
        Hero::CalendarDays(variant: :outline, class: "w-4 h-4 mr-1 text-content-muted")
        plain(article.published_at&.strftime("%Y년 %m월 %d일") || "N/A")
      end
    end
  end
end
