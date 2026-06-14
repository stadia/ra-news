# frozen_string_literal: true
# rbs_inline: enabled

module SitemapBuilder
  extend FunctionLogger

  HREFLANG_HOSTS = {
    "ko" => "https://ruby-news.dev",
    "ja" => "https://ruby-news.jp"
  }.freeze

  # published_at은 원문에서 파싱되므로 비현실적 값(예: 1935년, 미래 날짜)이
  # 들어올 수 있고, 그대로 lastmod에 쓰면 Google Search Console이 "잘못된
  # 날짜"로 사이트맵을 거부한다. Rails 등장(2004) 이전 floor로 사용한다.
  MIN_LASTMOD = Time.utc(2004, 1, 1)

  class << self
    include Rails.application.routes.url_helpers

    #: (String) -> Array[Hash[Symbol, String]]
    def alternates_for(path)
      HREFLANG_HOSTS.map { |lang, host| { href: "#{host}#{path}", lang: lang } }
    end

    # lastmod 안전값: published_at이 비현실적(2004년 이전 또는 미래)이거나
    # 없으면 신뢰 가능한 updated_at으로 대체한다.
    #: (Article) -> String?
    def lastmod_for(article)
      candidate = article.published_at
      if candidate.nil? || candidate < MIN_LASTMOD || candidate > Time.current
        candidate = article.updated_at
      end
      candidate&.iso8601
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
            lastmod = SitemapBuilder.lastmod_for(article)
            SitemapBuilder::HREFLANG_HOSTS.each_value do |host|
              add path, host: host, lastmod: lastmod, alternates: alternates
            end
          end
        end
      end
    end
  end
end
