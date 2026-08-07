# frozen_string_literal: true

require "rails_helper"

# 로케일별 publisher(NewsMediaOrganization) 스키마가 현재 호스트 도메인을
# 기준으로 생성되는지 검증한다. (이전에는 상수라 항상 .dev 로 고정돼 있었다)
RSpec.describe HomeController do
  describe ".publisher_schema" do
    it "ja 로케일은 url/logo/masthead 가 .jp 기준이다" do
      schema = described_class.publisher_schema(:ja)

      expect(schema.url).to eq("https://ruby-news.jp")
      expect(schema.logo).to eq("https://ruby-news.jp/icon.png")
      expect(schema.masthead).to eq("https://ruby-news.jp/about")
    end

    it "ko 로케일은 url/logo/masthead 가 .dev 기준이다" do
      schema = described_class.publisher_schema(:ko)

      expect(schema.url).to eq("https://ruby-news.dev")
      expect(schema.logo).to eq("https://ruby-news.dev/icon.png")
      expect(schema.masthead).to eq("https://ruby-news.dev/about")
    end

    it "same_as 는 로케일과 무관하게 양 도메인 핸들을 모두 포함한다" do
      same_as = described_class.publisher_schema(:ja).same_as

      expect(same_as).to include(
        "https://ruby-news.dev/@bot",
        "https://ruby.social/@news_kr",
        "https://x.com/rubynewskr"
      )
    end
  end
end
