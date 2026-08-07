# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hosts do
  describe ".for_locale" do
    it "ja 로케일은 .jp 호스트를 반환한다" do
      expect(described_class.for_locale(:ja)).to eq("https://ruby-news.jp")
    end

    it "ko 로케일은 .dev 호스트를 반환한다" do
      expect(described_class.for_locale(:ko)).to eq("https://ruby-news.dev")
    end

    it "심볼과 문자열 로케일을 동일하게 처리한다" do
      expect(described_class.for_locale("ja")).to eq(described_class.for_locale(:ja))
    end

    it "알 수 없는 로케일은 기본값(.dev)으로 폴백한다" do
      expect(described_class.for_locale(:en)).to eq(Hosts::DEFAULT)
      expect(described_class.for_locale(:fr)).to eq("https://ruby-news.dev")
    end
  end

  describe "LOCALE_FOR_HOST" do
    it "FOR_LOCALE 에서 host→locale 역방향으로 파생된다" do
      expect(Hosts::LOCALE_FOR_HOST).to eq(
        "ruby-news.dev" => :ko,
        "ruby-news.jp" => :ja
      )
    end

    it "FOR_LOCALE 와 키/값이 일관된다 (단일 정본)" do
      Hosts::FOR_LOCALE.each do |locale, url|
        host = URI(url).host
        expect(Hosts::LOCALE_FOR_HOST[host]).to eq(locale.to_sym)
      end
    end
  end
end
