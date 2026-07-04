# config/sitemap.rb
# 실행: bundle exec rake sitemap:refresh:no_ping
#
# 출력 파일:
#   public/sitemaps/sitemap.xml.gz        <- 사이트맵 인덱스
#   public/sitemaps/sitemap1..N.xml.gz    <- URL (max_sitemap_links=5,000마다 분할)
#
# ping 없음: Google은 2023년 말 sitemap ping 엔드포인트를 공식 폐지.
# 사이트맵 등록은 Google Search Console에서 직접 수행한다.

SitemapBuilder.build
