# typed: true
# frozen_string_literal: true

class Components::Articles::SearchTabs < Components::Base
  def initialize(source:, search: nil)
    @source = source
    @search = search
  end

  def view_template
    nav(
      aria_label: t("articles.index.search_source"),
      class: "mb-8 border-b border-border-subtle",
      role: "tablist"
    ) do
      tab(t("articles.index.tabs.ruby_news"), :ruby_news)
      tab(t("articles.index.tabs.google"), :google)
    end
  end

  private

  def tab(label, source)
    active = @source == source

    a(
      aria_current: active ? "page" : nil,
      aria_selected: active.to_s,
      class: tab_classes(active),
      data_turbo: "false",
      href: articles_path(source:, search: @search),
      role: "tab"
    ) { label }
  end

  def tab_classes(active)
    base = "inline-flex border-b-2 px-4 py-3 text-sm font-medium transition-colors"
    state = active ? "border-brand text-accent-text" : "border-border-subtle text-content-muted"
    "#{base} #{state}"
  end
end
