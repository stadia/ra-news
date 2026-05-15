# frozen_string_literal: true
# rbs_inline: enabled

#: Article의 summary_key를 기반으로 썸네일 이미지를 생성하여 ActiveStorage에 첨부한다
class ArticleThumbnailJob < ApplicationJob
  queue_as :default

  #: (Integer article_id) -> void
  def perform(article_id)
    article = Article.kept.find(article_id)

    if article.thumbnail.attached?
      logger.info "ArticleThumbnailJob skip: article #{article_id} already has thumbnail"
      return
    end

    summary_key = article.summary_key
    if summary_key.blank? || !summary_key.is_a?(Array) || summary_key.empty?
      logger.info "ArticleThumbnailJob skip: article #{article_id} has no summary_key"
      return
    end

    prompt = build_prompt(summary_key)
    message = ArticleImageAgent.new.ask(prompt)

    attachment = message.content[:attachments].first
    if attachment.blank?
      logger.warn "ArticleThumbnailJob failed: no image generated for article #{article_id}"
      return
    end

    ext = MIME::Types[attachment.mime_type].first&.preferred_extension || "png"
    article.thumbnail.attach(
      io: StringIO.new(attachment.content),
      filename: "thumbnail-#{article.id}.#{ext}",
      content_type: attachment.mime_type
    )
    logger.info "ArticleThumbnailJob attached thumbnail for article #{article_id}"
  rescue ActiveRecord::RecordNotFound
    logger.info "ArticleThumbnailJob skip: article #{article_id} not found"
  end

  private

  #: (Array[String] summary_key) -> String
  def build_prompt(summary_key)
    points = summary_key.each_with_index.map { |s, i| "#{i + 1}. #{s}" }.join("\n")
    <<~PROMPT.strip
      다음은 기술 뉴스 기사의 핵심 요약이다. 이 요약을 인포그래픽 썸네일 한 장으로 시각화한다.

      [요약]
      #{points}
    PROMPT
  end
end
