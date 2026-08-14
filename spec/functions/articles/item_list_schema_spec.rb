# frozen_string_literal: true

require "rails_helper"

RSpec.describe Articles::ItemListSchema do
  let(:urls) { %w[https://ruby-news.dev/articles/a https://ruby-news.dev/articles/b] }

  describe ".payload" do
    subject(:payload) { described_class.payload(name: "최신 기사", urls: urls) }

    it "불변 ItemList 값 객체를 구성한다" do
      expect(payload).to be_a(described_class::Payload)
      expect(payload.to_h).to include(
        "@context" => "https://schema.org",
        "@type" => "ItemList",
        "name" => "최신 기사",
        "itemListOrder" => "https://schema.org/ItemListOrderDescending",
        "numberOfItems" => 2
      )
    end

    it "URL 순서대로 1부터 position 을 매긴다" do
      expect(payload.to_h["itemListElement"]).to eq(
        [
          { "@type" => "ListItem", "position" => 1, "url" => urls.first },
          { "@type" => "ListItem", "position" => 2, "url" => urls.second }
        ]
      )
    end

    it "URL 이 없으면 빈 목록을 반환한다" do
      empty = described_class.payload(name: "최신 기사", urls: [])

      expect(empty.to_h["numberOfItems"]).to eq(0)
      expect(empty.to_h["itemListElement"]).to be_empty
    end

    it "URL 목록을 복사해 동결한다" do
      payload

      expect(payload.urls).to eq(urls)
      expect(payload.urls).to be_frozen
    end
  end

  describe ".json" do
    it "payload 를 JSON 문자열로 직렬화한다" do
      json = described_class.json(name: "최신 기사", urls: urls)

      expect(JSON.parse(json)).to eq(described_class.payload(name: "최신 기사", urls: urls).to_h)
    end
  end
end
