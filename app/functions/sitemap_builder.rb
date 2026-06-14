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
  MIN_LASTMOD = Time.zone.local(2004, 1, 1)

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
        # 페이지당 <loc>는 1개(canonical=ko, default_host)만 등재하고, ja(.jp)는
        # hreflang alternates로 연결한다. 양쪽을 모두 <loc>로 넣으면 GSC 발견
        # 페이지 수가 2배가 되므로 표준 방식(1 loc + alternates)을 따른다.
        # 목록 페이지 lastmod: 맨 날짜(Date)는 타임존이 없어 파서가 UTC 자정으로
        # 해석 → KST 오늘이 UTC 기준 미래로 보인다. 오프셋이 붙는 Time을 사용.
        index_lastmod = Time.current.iso8601
        add articles_path,
            lastmod: index_lastmod,
            alternates: SitemapBuilder.alternates_for(articles_path)
        add others_path,
            lastmod: index_lastmod,
            alternates: SitemapBuilder.alternates_for(others_path)

        # 참고: lastmod는 updated_at 대신 published_at 사용
        # (updated_at은 배경 Job이 건드릴 때마다 갱신되어 Google 오탐 발생)
        Article.kept
               .confirmed
               .find_in_batches(batch_size: 500) do |batch|
          batch.each do |article|
            path = article_path(article.slug)
            add path,
                lastmod: SitemapBuilder.lastmod_for(article),
                alternates: SitemapBuilder.alternates_for(path)
          end
        end
      end
    end
  end
end
