xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "RA-News - Ruby & Rails News"
    xml.description "최신 Ruby와 Rails 관련 뉴스 및 기술 아티클을 제공합니다"
    xml.link root_url
    xml.language "ko"
    xml.lastBuildDate @articles.first&.created_at&.rfc822 || Time.current.rfc822
    xml.ttl "60"

    @articles.each do |article|
      xml.item do
        xml.title article.title || "제목 없음"
        xml.description article.summary_detail || article.title || "설명 없음"
        xml.pubDate article.published_at&.rfc822 || article.created_at&.rfc822
        xml.link article_url(article)
        xml.guid article_url(article), isPermaLink: true
        xml.author article.user&.email if article.user&.email
      end
    end
  end
end