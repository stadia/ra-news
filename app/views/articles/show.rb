# frozen_string_literal: true

class Views::Articles::Show < Views::Base
  include PhlexIcons
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::Sanitize

  def initialize(article:, comments:, comment:, similar_articles:)
    @article = article
    @comments = comments
    @comment = comment
    @similar_articles = similar_articles
  end

  def view_template
    content_for(:title, @article.title_ko)

    # @news_article, @breadcrumbs are set as instance variables in ArticlesController#show
    # Insert schema.org JSON-LD into layout's head via content_for(:head)
    content_for :head, raw(@news_article.to_s) if @news_article
    content_for :head, raw(@breadcrumbs.to_s) if @breadcrumbs

    div(class: "space-y-6 lg:space-y-8 max-w-6xl mx-auto", id: dom_id(@article)) do
      render_article_main
      render_similar_articles if @similar_articles.present?
      render_comments_section
    end
  end

  private

  # Shift markdown headings so that # and ## become ### (minimum h3)
  def downshift_headings(markdown)
    markdown.gsub(/^(#+)\s/) do
      level = Regexp.last_match(1).length
      new_level = [ level + 2, 6 ].min
      "#" * new_level + " "
    end
  end

  def render_article_main
    article(class: "bg-surface rounded-xl shadow-lg overflow-hidden border border-border-strong") do
      render_article_header
      render RubyUI::Separator.new
      render_article_body
    end
  end

  def render_article_header
    header(class: "p-4 md:p-6 lg:p-8") do
      div(class: "mb-6") do
        render RubyUI::Heading.new(
          level: 1,
          class: "text-2xl! lg:text-3xl! font-bold text-content mb-4 leading-tight"
        ) { @article.title_ko }

        if @article.title_ko != @article.title
          render RubyUI::Heading.new(level: 2, class: "font-medium text-content-secondary mb-4 wrap-break-word") { @article.title }
        end
      end

      div(class: "flex flex-wrap items-center gap-4 md:gap-6 text-sm text-content-secondary") do
        div(class: "flex items-center") do
          div(class: "w-8 h-8 bg-brand-solid rounded-full flex items-center justify-center mr-3") do
            Hero::User(variant: :outline, class: "w-4 h-4 text-brand-foreground")
          end
          div do
            div(class: "text-xs text-content-secondary") { "작성자" }
            div(class: "font-medium text-content") do
              render(Components::Articles::ArticleUser.new(article: @article))
            end
          end
        end

        div(class: "flex items-center") do
          Hero::Calendar(variant: :outline, class: "w-5 h-5 mr-2 text-content-muted")
          div do
            div(class: "text-xs text-content-secondary") { "발행일" }
            div(class: "font-medium text-content") do
              time(datetime: @article.published_at&.iso8601) do
                plain @article.published_at&.strftime("%Y년 %m월 %d일") || "N/A"
              end
            end
          end
        end

        render Components::Likes::Button.new(likeable: @article)
      end

      div(class: "mt-6 p-4 bg-surface-muted rounded-lg") do
        div(class: "flex items-center min-w-0") do
          div(class: "w-10 h-10 bg-info-solid rounded-lg flex items-center justify-center mr-3 shrink-0") do
            Hero::ArrowTopRightOnSquare(variant: :outline, class: "w-5 h-5 text-brand-foreground")
          end
          div(class: "min-w-0 flex-1") do
            a(
              href: @article.url,
              target: "_blank",
              rel: "noopener noreferrer",
              class: "text-sm font-medium text-info-text hover:text-info-text-hover transition-colors wrap-break-word"
            ) { @article.url }
          end
        end
      end
    end
  end

  def render_article_body
    div(class: "p-4 md:p-6 lg:p-8") do
      section(class: "mb-8 lg:mb-12") do
        div(class: "bg-linear-to-r from-brand-solid to-brand-solid-hover rounded-lg p-6") do
          render RubyUI::Heading.new(
            level: 2,
            class: "font-bold text-brand-foreground mb-4 flex items-center"
          ) do
            Hero::CheckCircle(variant: :outline, class: "w-6 h-6 mr-2")
            plain "핵심 요약"
          end

          if @article.summary_key.is_a?(Array)
            ul(class: "space-y-3") do
              @article.summary_key&.each_with_index do |item, index|
                li(class: "flex items-start") do
                  span(class: "shrink-0 w-5 text-brand-foreground/60 font-semibold text-sm tabular-nums mt-0.5 mr-2 text-right") do
                    plain "#{index + 1}."
                  end
                  span(class: "text-brand-foreground leading-relaxed") { plain item }
                end
              end
            end
          end
        end
      end

      section(class: "prose dark:prose-invert prose-lg max-w-none prose-headings:text-prose-heading-accent prose-strong:text-prose-strong-accent") do
        if @article.summary_detail.is_a?(Hash)
          if @article.summary_detail["introduction"].present?
            div(class: "mb-8 p-6 bg-surface-muted rounded-xl border-l-4 border-state-info") do
              render RubyUI::Heading.new(level: 3, class: "font-semibold text-info-text mb-3") { "도입" }
              div(class: "text-content-secondary leading-relaxed text-base") do
                plain @article.summary_detail["introduction"]
              end
            end
          end

          if @article.summary_body.present?
            div(class: "mb-8 article-content", id: "article-detail-body") do
              div(class: "prose dark:prose-invert max-w-none prose-headings:text-prose-heading-accent prose-h1:text-2xl prose-h2:text-xl prose-h3:text-lg prose-h4:text-base prose-strong:text-prose-strong-accent text-content-secondary leading-loose") do
                raw sanitize(Kramdown::Document.new(downshift_headings(@article.summary_body)).to_html)
              end
            end
          end

          if @article.summary_detail["conclusion"].present?
            div(class: "p-6 bg-surface-muted rounded-xl border-l-4 border-brand") do
              render RubyUI::Heading.new(level: 3, class: "font-semibold text-accent-text mb-3") { "결론" }
              div(class: "text-content-secondary leading-relaxed text-base") do
                plain @article.summary_detail["conclusion"]
              end
            end
          end
        end
      end
    end
  end

  def render_similar_articles
    render RubyUI::Card.new(class: "bg-surface shadow-lg overflow-hidden border-border-strong") do
      render RubyUI::CardContent.new(class: "p-4 md:p-6 lg:p-8") do
        render RubyUI::Heading.new(level: 2, class: "font-bold text-content mb-6 flex items-center") do
          Hero::Newspaper(variant: :outline, class: "w-6 h-6 mr-2 text-brand")
          plain "관련 글들"
        end

        div(class: "grid grid-cols-1 md:grid-cols-2 gap-4 lg:gap-6") do
          @similar_articles.each do |article|
            div(class: "group bg-surface-muted rounded-lg border border-border-muted hover:border-border-strong transition-all duration-200 overflow-hidden") do
              link_to(article_path(article), class: "block p-4 lg:p-6") do
                render RubyUI::Heading.new(
                  level: 3,
                  class: "font-semibold text-content group-hover:text-link-hover transition-colors duration-200 mb-3 line-clamp-2"
                ) { article.title_ko || article.title }

                p(class: "text-content-secondary text-sm leading-relaxed line-clamp-3 mb-4") do
                  plain(if article.summary_key.is_a?(String)
                    article.summary_key
                  else
                    article.summary_key&.first
                  end)
                end

                div(class: "flex items-center justify-between text-xs text-content-secondary") do
                  span(class: "flex items-center") do
                    Hero::Calendar(variant: :outline, class: "w-4 h-4 mr-1")
                    plain article.published_at&.strftime("%m/%d")
                  end
                  span(class: "group-hover:text-link-hover transition-colors duration-200") { "읽어보기 →" }
                end
              end
            end
          end
        end
      end
    end
  end

  def render_comments_section
    render RubyUI::Card.new(class: "bg-surface shadow-lg overflow-hidden border-border-strong") do
      render RubyUI::CardContent.new(class: "p-4 md:p-6 lg:p-8") do
        render RubyUI::Heading.new(
          level: 3,
          class: "font-bold text-content mb-6 flex items-center",
          id: "comments_header"
        ) { render(Components::Comments::CommentHeader.new(comments: @comments)) }

        render RubyUI::Separator.new(class: "mb-4")
        div(id: "comment_form") do
          render(Components::Comments::CommentForm.new(article: @article, comment: @comment))
        end

        div(class: "space-y-4 pt-6") do
          render(Components::Comments::Comments.new(article: @article, comments: @comments))
        end
      end
    end
  end
end
