# frozen_string_literal: true

require "rails_helper"

# /llms.txt 가 호스트(로케일)별로 다른 본문을 서빙하는지 검증한다.
# 이전에는 public/llms.txt 정적 파일이라 .jp 에서도 한국어/.dev 만 서빙됐다.
RSpec.describe "llms.txt", type: :request do
  it "ja 호스트는 일본어 본문 + .jp URL 을 서빙한다" do
    host! "ruby-news.jp"
    get "/llms.txt"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/plain")
    expect(response.body).to include("Ruby AI ニュース")
    expect(response.body).to include("https://ruby-news.jp/")
    expect(response.body).not_to include("루비 AI 뉴스")
  end

  it "ko 호스트는 한국어 본문 + .dev URL 을 서빙한다" do
    host! "ruby-news.dev"
    get "/llms.txt"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/plain")
    expect(response.body).to include("루비 AI 뉴스")
    expect(response.body).to include("https://ruby-news.dev/")
    expect(response.body).not_to include("Ruby AI ニュース")
  end

  # Codex P1 회귀 방지: public 캐시이므로 본문은 쿠키·사용자 로케일이 아니라
  # 요청 호스트로 결정해야 한다. ko 쿠키가 있어도 .jp 호스트면 일본어를 서빙한다.
  it "쿠키 로케일(ko)이 있어도 .jp 호스트면 일본어를 서빙한다" do
    cookies[:locale] = "ko"
    host! "ruby-news.jp"
    get "/llms.txt"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ruby AI ニュース")
    expect(response.body).not_to include("루비 AI 뉴스")
  end
end
