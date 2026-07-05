# config/sitemap.rb
# 실행: bundle exec rake sitemap:refresh:no_ping
#
# 출력 파일 (도메인별 자기 완결 사이트맵):
#   public/sitemaps/ko/sitemap.xml.gz      <- .dev(ko) 인덱스
#   public/sitemaps/ko/sitemap1..N.xml.gz  <- .dev URL (max_sitemap_links=5,000마다 분할)
#   public/sitemaps/ja/sitemap.xml.gz      <- .jp(ja) 인덱스
#   public/sitemaps/ja/sitemap1..N.xml.gz  <- .jp URL
#
# ping 없음: Google은 2023년 말 sitemap ping 엔드포인트를 공식 폐지.
# 사이트맵 등록은 Google Search Console에서 직접 수행한다.

SitemapBuilder.build
