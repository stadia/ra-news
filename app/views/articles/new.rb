# frozen_string_literal: true

class Views::Articles::New < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo

  attr_reader :article

  def initialize(article:)
    @article = article
  end

  def view_template
    content_for :title, "새 글 등록"

    section(class: "max-w-2xl mx-auto py-12 px-4 sm:px-6") do
      div(class: "mb-6 sm:mb-8") do
        render RubyUI::Badge.new(variant: :emerald, size: :sm, class: "mb-2 tracking-[0.22em] uppercase") { "Article Intake" }
        render RubyUI::Heading.new(level: 1, class: "font-bold text-content text-3xl sm:text-4xl tracking-tight") { "새 글 등록" }
        p(class: "mt-2 text-content-secondary/80 text-sm sm:text-base") { "URL을 입력하면 수집과 요약 처리를 시작합니다." }
      end

      render RubyUI::Card.new(class: "relative overflow-hidden rounded-2xl border-border-strong/70 bg-app/70 shadow-2xl shadow-black/30 p-5 sm:p-7 lg:p-8 backdrop-blur-sm") do
        div(class: "pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(16,185,129,0.16),transparent_42%)]")
        div(class: "relative") do
          render Components::Articles::Form.new(article: article)
        end
      end

      div(class: "mt-5 flex items-center justify-end") do
        render RubyUI::Link.new(
          href: articles_path,
          variant: :primary,
          size: :lg,
          class:
            "inline-flex items-center justify-center rounded-xl px-4 py-2.5 border border-border-muted bg-surface/80 hover:bg-surface-hover text-content font-semibold transition-all focus:outline-none focus:ring-2 focus:ring-brand focus:ring-offset-2 focus:ring-offset-app",
        ) { "목록으로 돌아가기" }
      end
    end
  end
end
