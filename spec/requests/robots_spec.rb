# frozen_string_literal: true

require "rails_helper"

# /robots.txt 가 호스트별로 "자기 도메인 사이트맵만" 광고하는지 검증한다.
# 이전에는 public/robots.txt 정적 파일 하나가 양 도메인에 동일하게 서빙돼,
# .jp 에서도 .dev 사이트맵을, .dev 에서도 .jp 사이트맵을 함께 노출했다.
# 두 도메인을 독립 사이트로 취급하려면 각자 자기 사이트맵만 내보내야 한다.
RSpec.describe "robots.txt", type: :request do
  it "ja(.jp) 호스트는 .jp 사이트맵만 광고한다" do
    host! "ruby-news.jp"
    get "/robots.txt"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/plain")
    expect(response.body).to include("Sitemap: https://ruby-news.jp/sitemaps/ja/sitemap.xml.gz")
    expect(response.body).not_to include("ruby-news.dev")
  end

  it "ko(.dev) 호스트는 .dev 사이트맵만 광고한다" do
    host! "ruby-news.dev"
    get "/robots.txt"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/plain")
    expect(response.body).to include("Sitemap: https://ruby-news.dev/sitemaps/ko/sitemap.xml.gz")
    expect(response.body).not_to include("ruby-news.jp")
  end

  it "공통 디렉티브(관리 경로 차단, AI 학습 봇 차단)는 유지된다" do
    host! "ruby-news.dev"
    get "/robots.txt"

    expect(response.body).to include("Disallow: /admin")
    expect(response.body).to include("User-agent: GPTBot")
  end
end
