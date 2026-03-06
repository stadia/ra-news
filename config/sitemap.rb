# config/sitemap.rb
# 실행: bundle exec rake sitemap:refresh:no_ping
#
# 출력 파일:
#   public/sitemaps/sitemap.xml.gz   <- 사이트맵 인덱스
#   public/sitemaps/sitemap1.xml.gz  <- 전체 URL
#
# ping 없음: Google은 2023년 말 sitemap ping 엔드포인트를 공식 폐기.
# 사이트맵 등록은 Google Search Console에서 직접 수행한다.

SitemapGenerator::Sitemap.default_host  = "https://ruby-news.kr"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"
SitemapGenerator::Sitemap.compress      = true

SitemapGenerator::Sitemap.create do
  add articles_path, lastmod: Date.today

  # 참고: find_in_batches는 order: 옵션을 지원하지 않으므로
  # scope에서 먼저 order()를 호출한 후 find_in_batches 적용.
  # lastmod는 updated_at 대신 published_at 사용
  # (updated_at은 배경 Job이 건드릴 때마다 갱신되어 Google 오탐 발생)
  Article.kept
         .confirmed
         .order(published_at: :desc)
         .find_in_batches(batch_size: 500) do |batch|
    batch.each do |article|
      add article_path(article.slug),
          lastmod: article.published_at || article.updated_at
    end
  end
end
