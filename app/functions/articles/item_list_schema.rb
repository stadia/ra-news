# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  # 기사 목록 페이지(home/index, articles/index·tagged·others)가 공유하는
  # schema.org ItemList payload 빌더. 뷰는 렌더만 담당하고 payload 구성은
  # 여기서 한다.
  module ItemListSchema
    SCHEMA_CONTEXT = "https://schema.org"
    DESCENDING_ORDER = "https://schema.org/ItemListOrderDescending"

    Payload = Data.define(:name, :urls)

    class Payload
      def to_h
        {
          "@context" => SCHEMA_CONTEXT,
          "@type" => "ItemList",
          "name" => name,
          "itemListOrder" => DESCENDING_ORDER,
          "numberOfItems" => urls.size,
          "itemListElement" => urls.each_with_index.map do |url, index|
            {
              "@type" => "ListItem",
              "position" => index + 1,
              "url" => url
            }
          end
        }
      end
    end

    class << self
      #: (name: String, urls: Array[String]) -> Payload
      def payload(name:, urls:)
        Payload.new(name: name.dup.freeze, urls: urls.map { |url| url.dup.freeze }.freeze)
      end

      #: (name: String, urls: Array[String]) -> String
      def json(name:, urls:)
        JSON.generate(payload(name: name, urls: urls).to_h)
      end
    end
  end
end
