# typed: true
# frozen_string_literal: true

# 기사 목록 페이지의 ItemList JSON-LD 를 렌더한다.
# payload 구성은 Articles::ItemListSchema 가 담당한다.
class Components::StructuredData::ItemList < Components::Base
  def initialize(name:, articles:)
    @name = name
    @articles = articles
  end

  def view_template
    return if @articles.blank?

    script(type: "application/ld+json") do
      raw(json_ld.html_safe)
    end
  end

  private

  def json_ld
    # Components::Articles 네임스페이스가 있어 상대 경로로 쓰면 그쪽으로 잡힌다.
    ::Articles::ItemListSchema.json(
      name: @name,
      urls: @articles.map { |article| article_url(article) }
    )
  end
end
