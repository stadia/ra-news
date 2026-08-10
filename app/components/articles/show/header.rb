# typed: true
# frozen_string_literal: true

# 기사 상세 상단: 히어로 썸네일 + 제목/메타 정보 + 원문 링크.
class Components::Articles::Show::Header < Components::Base
  include PhlexIcons
  include Phlex::Rails::Helpers::ImageTag

  def initialize(presenter:)
    @presenter = presenter
    @article = presenter.article
  end

  def view_template
    render_hero_thumbnail
    render_header
  end

  private

  def render_hero_thumbnail
    return unless @presenter.hero_thumbnail?

    div(class: "w-full overflow-hidden") do
      image_tag(
        cdn_variant_url(@article.thumbnail, :hero),
        class: "w-full aspect-video object-cover",
        srcset: "#{cdn_variant_url(@article.thumbnail, :card)} 600w, #{cdn_variant_url(@article.thumbnail, :hero)} 1200w",
        sizes: "(min-width: 768px) 768px, 100vw",
        loading: "eager",
        decoding: "auto",
        fetchpriority: "high",
        alt: @article.display_title
      )
    end
  end

  def render_header
    header(class: "p-4 md:p-6 lg:p-8") do
      div(class: "mb-6") do
        render RubyUI::Heading.new(
          level: 1,
          class: "text-2xl! lg:text-3xl! font-bold text-content mb-4 leading-tight"
        ) { @article.display_title }

        p(class: "text-lg font-medium text-content-secondary mb-4 wrap-break-word") { @article.title }
      end

      render_meta_row
      render_source_link
    end
  end

  def render_meta_row
    div(class: "flex flex-wrap items-center gap-4 md:gap-6 text-sm text-content-secondary") do
      render_author
      render_published_at

      render Components::Likes::Button.new(likeable: @article)
      render Components::Boosts::Button.new(boostable: @article)
      render_markdown_copy_button
    end
  end

  def render_author
    div(class: "flex items-center") do
      div(class: "w-8 h-8 bg-brand-solid rounded-full flex items-center justify-center mr-3") do
        Hero::User(variant: :outline, class: "w-4 h-4 text-brand-foreground")
      end
      div do
        div(class: "text-xs text-content-secondary") { t("articles.show.author") }
        div(class: "font-medium text-content") do
          render(Components::Articles::ArticleUser.new(article: @article))
        end
      end
    end
  end

  def render_published_at
    div(class: "flex items-center") do
      Hero::Calendar(variant: :outline, class: "w-5 h-5 mr-2 text-content-muted")
      div do
        div(class: "text-xs text-content-secondary") { t("articles.show.published_at") }
        div(class: "font-medium text-content") do
          time(datetime: @presenter.published_at_iso) do
            plain @presenter.published_at_label(t("articles.show.date_format")) || t("articles.show.not_available")
          end
        end
      end
    end
  end

  def render_markdown_copy_button
    button(
      type: "button",
      class: "inline-flex items-center gap-1 text-sm text-content-muted hover:text-brand transition-colors p-0",
      aria_label: t("articles.show.copy_markdown"),
      data: {
        controller: "markdown-copy",
        markdown_copy_url_value: article_path(@article, format: :md),
        action: "markdown-copy#copy"
      }
    ) do
      Tabler::Markdown(variant: :outline, class: "w-4 h-4")
      span(
        data: { markdown_copy_target: "label", done_label: t("articles.show.copy_markdown_done") }
      ) { t("articles.show.copy_markdown") }
    end
  end

  def render_source_link
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
