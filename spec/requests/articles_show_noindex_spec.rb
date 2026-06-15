# frozen_string_literal: true

require "rails_helper"

# .jp(ja) 로케일에서 일본어 번역이 없는 기사는 한국어 원문으로 폴백되므로,
# 검색/AI 에 "한국어를 일본어로" 노출하지 않도록 noindex 처리하고 ja hreflang
# alternate 도 광고하지 않는다(번역되면 자동으로 색인 복귀). ko(.dev)는 원문
# 언어이므로 항상 색인된다.
RSpec.describe "Articles show noindex / hreflang by translation availability", type: :request do
  fixtures :articles, :users, :sites, :federails_actors

  let(:article) { articles(:ruby_article) }

  def robots_meta(body)
    body[%r{<meta name="robots" content="([^"]+)">}, 1]
  end

  def hreflang_locales(body)
    body.scan(%r{<link rel="alternate" hreflang="([^"]+)" href}).flatten
  end

  context "일본어 번역이 없는 기사 (title_ja 없음)" do
    before { article.update!(title_ja: nil) }

    it ".jp 호스트에서 noindex 이고 ja hreflang alternate 가 없다" do
      host! "ruby-news.jp"
      get "/articles/#{article.slug}"

      expect(response).to have_http_status(:ok)
      expect(robots_meta(response.body)).to eq("noindex, follow")

      locales = hreflang_locales(response.body)
      expect(locales).to include("ko")
      expect(locales).not_to include("ja")
    end

    it ".dev(ko) 호스트에서는 색인 가능하다 (noindex 없음)" do
      host! "ruby-news.dev"
      get "/articles/#{article.slug}"

      expect(response).to have_http_status(:ok)
      expect(robots_meta(response.body)).to be_nil
    end
  end

  context "일본어 번역이 있는 기사 (title_ja 존재)" do
    before { article.update!(title_ja: "Ruby 3.4 の新機能") }

    it ".jp 호스트에서 색인 가능하고 ja/ko hreflang 을 모두 광고한다" do
      host! "ruby-news.jp"
      get "/articles/#{article.slug}"

      expect(response).to have_http_status(:ok)
      expect(robots_meta(response.body)).to be_nil
      expect(hreflang_locales(response.body)).to include("ko", "ja")
    end
  end
end
