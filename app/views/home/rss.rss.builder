xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Ruby-News || 루비 AI 뉴스"
    xml.description "최신 Ruby, Rails 관련 뉴스와 트렌드를 한곳에서 만나보세요"
    xml.link root_url
    xml.language "ko"
    xml.lastBuildDate @articles.first&.created_at&.rfc822 || Time.current.rfc822
    xml.ttl "60"

    @articles.each do |article|
      xml.item do
        xml.title article.title_ko || article.title || "제목 없음"
        xml.description article.summary_key&.join("\n") || "핵심 요약이 없습니다"
        xml.pubDate article.published_at&.rfc822 || article.created_at&.rfc822
        xml.link article_url(article.slug || article.id)
        xml.guid article_url(article.slug || article.id), isPermaLink: true
        xml.author article.user_name
      end
    end
  end
end
