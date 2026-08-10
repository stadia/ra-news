# typed: true
# frozen_string_literal: true

# 기사 상세 본문: 핵심 요약 박스 + 서론/본문/결론.
class Components::Articles::Show::Summary < Components::Base
  include PhlexIcons
  include Phlex::Rails::Helpers::Sanitize

  def initialize(presenter:)
    @presenter = presenter
  end

  def view_template
    div(class: "p-4 md:p-6 lg:p-8") do
      render_summary_key
      render_summary_detail
    end
  end

  private

  def render_summary_key
    section(class: "mb-8 lg:mb-12") do
      div(class: "bg-linear-to-r from-brand-solid to-brand-solid-hover rounded-lg p-6") do
        render RubyUI::Heading.new(
          level: 2,
          class: "font-bold text-brand-foreground mb-4 flex items-center"
        ) do
          Hero::CheckCircle(variant: :outline, class: "w-6 h-6 mr-2")
          plain t("articles.show.summary_heading")
        end

        render_summary_key_items if @presenter.summary_key_items?
      end
    end
  end

  def render_summary_key_items
    ul(class: "space-y-3") do
      @presenter.summary_key_items.each_with_index do |item, index|
        li(class: "flex items-start") do
          span(class: "shrink-0 w-5 text-brand-foreground/60 font-semibold text-sm tabular-nums mt-0.5 mr-2 text-right") do
            plain "#{index + 1}."
          end
          span(class: "text-brand-foreground leading-relaxed") { plain item }
        end
      end
    end
  end

  def render_summary_detail
    section(class: "prose dark:prose-invert prose-lg max-w-none prose-headings:text-prose-heading-accent prose-strong:text-prose-strong-accent") do
      render_introduction
      render_body
      render_conclusion
    end
  end

  def render_introduction
    introduction = @presenter.introduction
    return if introduction.blank?

    div(class: "mb-8 p-6 bg-surface-muted rounded-xl border-l-4 border-state-info") do
      render RubyUI::Heading.new(level: 3, class: "font-semibold text-info-text mb-3") { t("articles.show.intro_heading") }
      div(class: "text-content-secondary leading-relaxed text-base") do
        plain introduction
      end
    end
  end

  def render_body
    body_markdown = @presenter.summary_body
    return if body_markdown.blank?

    div(class: "mb-8 article-content", id: "article-detail-body") do
      div(class: "prose dark:prose-invert max-w-none prose-headings:text-prose-heading-accent prose-h1:text-2xl prose-h2:text-xl prose-h3:text-lg prose-h4:text-base prose-strong:text-prose-strong-accent text-content-secondary leading-loose") do
        raw sanitize(Inkmark.to_html(body_markdown, options: { preset: :trusted }))
      end
    end
  end

  def render_conclusion
    conclusion = @presenter.conclusion
    return if conclusion.blank?

    div(class: "p-6 bg-surface-muted rounded-xl border-l-4 border-brand") do
      render RubyUI::Heading.new(level: 3, class: "font-semibold text-accent-text mb-3") { t("articles.show.conclusion_heading") }
      div(class: "text-content-secondary leading-relaxed text-base") do
        plain conclusion
      end
    end
  end
end
