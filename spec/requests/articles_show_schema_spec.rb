# frozen_string_literal: true

require "rails_helper"

# 기사 show 페이지의 NewsArticle JSON-LD 가 GEO 수정으로 추가된 키
# (author / translationOfWork / speakable)를 포함하고, publisher 호스트가
# 요청 호스트에 맞는지 검증한다. JSON-LD 는 pretty-print 되므로 파싱해서 확인한다.
RSpec.describe "Articles show NewsArticle JSON-LD", type: :request do
  fixtures :articles, :users, :sites, :fedipub_actors

  let(:article) { articles(:ruby_article) }

  def news_article_ld(body)
    body
      .scan(%r{<script type="application/ld\+json">(.*?)</script>}m)
      .map { |match| JSON.parse(match.first) }
      .find { |hash| hash["@type"] == "NewsArticle" }
  end

  it "ja 호스트에서 신규 스키마 키와 .jp publisher 를 출력한다" do
    host! "ruby-news.jp"
    get "/articles/#{article.slug}"

    expect(response).to have_http_status(:ok)

    ld = news_article_ld(response.body)
    expect(ld).to be_present
    expect(ld["inLanguage"]).to eq("ja-JP")
    # translationOfWork 는 원문 URL 을 가진 CreativeWork 객체여야 한다 (M2 / Codex P2)
    expect(ld["translationOfWork"]).to include("@type" => "CreativeWork", "url" => article.url)
    # author 추가 (H3)
    expect(ld["author"]).to be_present
    # speakable (M2)
    expect(ld["speakable"]).to include("@type" => "SpeakableSpecification")
    expect(ld.dig("speakable", "cssSelector")).to include("#article-detail-body")
    # publisher 호스트 로케일화 (C1)
    expect(ld.dig("publisher", "url")).to eq("https://ruby-news.jp")
  end

  it "ko 호스트에서는 inLanguage 가 ko-KR, publisher 가 .dev 이다" do
    host! "ruby-news.dev"
    get "/articles/#{article.slug}"

    expect(response).to have_http_status(:ok)

    ld = news_article_ld(response.body)
    expect(ld["inLanguage"]).to eq("ko-KR")
    expect(ld.dig("publisher", "url")).to eq("https://ruby-news.dev")
  end

  # Codex P2 회귀 방지: 쿠키 로케일이 ko 여도 .jp 호스트면 publisher 는 .jp 여야 한다.
  # (publisher = "어느 사이트냐"는 호스트로 결정. 캐시 오염/잘못된 도메인 노출 방지)
  it "쿠키 로케일(ko)이 있어도 .jp 호스트면 publisher 는 .jp 다" do
    cookies[:locale] = "ko"
    host! "ruby-news.jp"
    get "/articles/#{article.slug}"

    expect(response).to have_http_status(:ok)
    ld = news_article_ld(response.body)
    expect(ld.dig("publisher", "url")).to eq("https://ruby-news.jp")
  end
end
