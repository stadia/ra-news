# frozen_string_literal: true

require "rails_helper"

# .jp(ja) 로케일에서 일본어 번역이 없는 기사는 한국어 원문으로 폴백되므로,
# 검색/AI 에 "한국어를 일본어로" 노출하지 않도록 noindex 처리한다(번역되면
# 자동으로 색인 복귀). ko(.dev)는 원문 언어이므로 항상 색인된다.
#
# 또한 ruby-news.dev 와 ruby-news.jp 는 완전히 독립적인 사이트로 취급하므로
# 로케일 간 hreflang alternate 링크는 어떤 페이지에도 발행하지 않는다.
RSpec.describe "Articles show noindex by translation availability", type: :request do
  fixtures :articles, :users, :sites, :fedipub_actors

  let(:article) { articles(:ruby_article) }

  def robots_meta(body)
    body[%r{<meta name="robots" content="([^"]+)">}, 1]
  end

  def hreflang_locales(body)
    body.scan(%r{<link rel="alternate" hreflang="([^"]+)" href}).flatten
  end

  context "일본어 번역이 없는 기사 (summary_key_ja 없음)" do
    # 번역 완료 신호는 summary_key_ja(번역 파이프라인이 세팅). title_ja는
    # 일본어 원문 제목으로 미리 채워질 수 있어 신호로 쓰지 않는다(#809).
    before { article.update!(title_ja: nil, summary_key_ja: nil) }

    it ".jp 호스트에서 noindex 이고 hreflang 링크가 없다" do
      host! "ruby-news.jp"
      get "/articles/#{article.slug}"

      expect(response).to have_http_status(:ok)
      expect(robots_meta(response.body)).to eq("noindex, follow")
      expect(hreflang_locales(response.body)).to be_empty
    end

    it ".dev(ko) 호스트에서는 색인 가능하다 (noindex 없음)" do
      host! "ruby-news.dev"
      get "/articles/#{article.slug}"

      expect(response).to have_http_status(:ok)
      expect(robots_meta(response.body)).to be_nil
    end
  end

  context "일본어 번역이 있는 기사 (summary_key_ja 존재)" do
    before { article.update!(title_ja: "Ruby 3.4 の新機能", summary_key_ja: [ "Ruby 3.4 の主な改善点" ]) }

    it ".jp 호스트에서 색인 가능하고 hreflang 링크가 없다" do
      host! "ruby-news.jp"
      get "/articles/#{article.slug}"

      expect(response).to have_http_status(:ok)
      expect(robots_meta(response.body)).to be_nil
      expect(hreflang_locales(response.body)).to be_empty
    end
  end
end
