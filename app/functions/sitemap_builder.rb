# frozen_string_literal: true
# rbs_inline: enabled

module SitemapBuilder
  module_function

  include Rails.application.routes.url_helpers

  HREFLANG_HOSTS = {
    "ko" => "https://ruby-news.dev",
    "ja" => "https://ruby-news.jp"
  }.freeze

  #: (String) -> Array[Hash[Symbol, String]]
  def alternates_for(path)
    HREFLANG_HOSTS.map { |lang, host| { href: "#{host}#{path}", lang: lang } }
  end

  #: () -> void
  def build
    SitemapGenerator::Sitemap.default_host  = "https://ruby-news.dev"
    SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"
    SitemapGenerator::Sitemap.compress      = true

    SitemapGenerator::Sitemap.create do
      add articles_path,
          lastmod: Date.current.iso8601,
          alternates: SitemapBuilder.alternates_for(articles_path)
      add others_path,
          lastmod: Date.current.iso8601,
          alternates: SitemapBuilder.alternates_for(others_path)

      # 참고: lastmod는 updated_at 대신 published_at 사용
      # (updated_at은 배경 Job이 건드릴 때마다 갱신되어 Google 오탐 발생)
      Article.kept
             .confirmed
             .find_in_batches(batch_size: 500) do |batch|
        batch.each do |article|
          path = article_path(article.slug)
          add path,
              lastmod: (article.published_at || article.updated_at)&.iso8601,
              alternates: SitemapBuilder.alternates_for(path)
        end
      end
    end
  end
end
