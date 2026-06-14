# frozen_string_literal: true
# rbs_inline: enabled

module SitemapBuilder
  extend FunctionLogger

  HREFLANG_HOSTS = {
    "ko" => "https://ruby-news.dev",
    "ja" => "https://ruby-news.jp"
  }.freeze

  class << self
    include Rails.application.routes.url_helpers

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
        # 각 로케일 호스트(ko=.dev, ja=.jp)를 독립 <loc>로 등재해, 일본어
        # canonical(ruby-news.jp)도 사이트맵의 1급 항목이 되도록 한다.
        # 모든 항목은 동일한 hreflang alternates 세트를 함께 싣는다.
        SitemapBuilder::HREFLANG_HOSTS.each_value do |host|
          add articles_path, host: host,
              lastmod: Date.current.iso8601,
              alternates: SitemapBuilder.alternates_for(articles_path)
          add others_path, host: host,
              lastmod: Date.current.iso8601,
              alternates: SitemapBuilder.alternates_for(others_path)
        end

        # 참고: lastmod는 updated_at 대신 published_at 사용
        # (updated_at은 배경 Job이 건드릴 때마다 갱신되어 Google 오탐 발생)
        Article.kept
               .confirmed
               .find_in_batches(batch_size: 500) do |batch|
          batch.each do |article|
            path = article_path(article.slug)
            alternates = SitemapBuilder.alternates_for(path)
            lastmod = (article.published_at || article.updated_at)&.iso8601
            SitemapBuilder::HREFLANG_HOSTS.each_value do |host|
              add path, host: host, lastmod: lastmod, alternates: alternates
            end
          end
        end
      end
    end
  end
end
