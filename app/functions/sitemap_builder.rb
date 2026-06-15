# frozen_string_literal: true
# rbs_inline: enabled

module SitemapBuilder
  extend FunctionLogger

  # 단일 소스: app/functions/hosts.rb (Hosts::FOR_LOCALE)
  HREFLANG_HOSTS = Hosts::FOR_LOCALE

  # published_at은 원문에서 파싱되므로 비현실적 값(예: 1935년, 미래 날짜)이
  # 들어올 수 있고, 그대로 lastmod에 쓰면 Google Search Console이 "잘못된
  # 날짜"로 사이트맵을 거부한다. Rails 등장(2004) 이전 floor로 사용한다.
  MIN_LASTMOD = Time.zone.local(2004, 1, 1)

  class << self
    include Rails.application.routes.url_helpers

    #: (String, ?Array[String]) -> Array[Hash[Symbol, String]]
    def alternates_for(path, locales = HREFLANG_HOSTS.keys)
      alternate_path = path == root_path ? "" : path

      HREFLANG_HOSTS.slice(*locales).map { |lang, host| { href: "#{host}#{alternate_path}", lang: lang } }
    end

    # lastmod는 실제 문서 변경 시점을 나타내야 하므로 published_at만 쓰면
    # 발행 이후 제목/요약/번역 수정이 검색엔진에 전달되지 않는다.
    # 별도 content_updated_at이 없으므로 안전한 published_at/updated_at 중 최신값을 사용한다.
    #: (Article) -> String?
    def lastmod_for(article)
      [ article.published_at, article.updated_at ]
        .compact
        .select { |candidate| realistic_lastmod?(candidate) }
        .max
        &.iso8601
    end

    #: (Time) -> bool
    def realistic_lastmod?(candidate)
      candidate >= MIN_LASTMOD && candidate <= Time.current
    end

    #: () -> void
    def build
      SitemapGenerator::Sitemap.default_host  = "https://ruby-news.dev"
      SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"
      SitemapGenerator::Sitemap.compress      = true
      SitemapGenerator::Sitemap.include_root  = false

      SitemapGenerator::Sitemap.create do
        # 각 로케일 호스트(ko=.dev, ja=.jp)를 개별 <url> 블록으로 등재한다.
        # 각 블록은 자신의 <loc> 1개 + ko/ja hreflang alternates를 모두 포함하는
        # Google 권장 다국어 사이트맵 구조다. ko·ja가 각각 색인 대상이므로
        # GSC 발견 페이지 수가 2배가 되는 것은 정상이다.
        # 목록 페이지 lastmod: 맨 날짜(Date)는 타임존이 없어 파서가 UTC 자정으로 해석 → KST 오늘이 UTC 기준 미래로 보인다. 오프셋이 붙는 Time을 사용.
        index_lastmod = Time.current.iso8601
        SitemapBuilder::HREFLANG_HOSTS.each_value do |host|
          add root_path, host: host,
              lastmod: index_lastmod,
              alternates: SitemapBuilder.alternates_for(root_path)
          add articles_path, host: host,
              lastmod: index_lastmod,
              alternates: SitemapBuilder.alternates_for(articles_path)
          add others_path, host: host,
              lastmod: index_lastmod,
              alternates: SitemapBuilder.alternates_for(others_path)
        end

        Article.kept
               .confirmed
               .find_in_batches(batch_size: 500) do |batch|
          batch.each do |article|
            path = article_path(article.slug)
            lastmod = SitemapBuilder.lastmod_for(article)
            # 번역이 존재하는 로케일 호스트만 등재한다. 일본어 번역이 없는
            # 기사는 .jp(<loc>·hreflang alternate) 에서 제외 → 한국어 폴백을
            # 일본어로 색인시키지 않는다. 번역되면 다음 빌드에서 자동 포함.
            available = SitemapBuilder::HREFLANG_HOSTS.keys.select { |loc| article.available_in?(loc) }
            alternates = SitemapBuilder.alternates_for(path, available)
            SitemapBuilder::HREFLANG_HOSTS.each do |locale, host|
              next unless article.available_in?(locale)
              add path, host: host, lastmod: lastmod, alternates: alternates
            end
          end
        end
      end
    end
  end
end
