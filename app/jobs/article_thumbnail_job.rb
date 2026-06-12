# frozen_string_literal: true
# rbs_inline: enabled

#: Article의 summary_key를 기반으로 썸네일 이미지를 생성하여 ActiveStorage에 첨부한다
class ArticleThumbnailJob < ApplicationJob
  queue_as :default

  #: (Integer article_id, ?force: bool) -> void
  def perform(article_id, force: false)
    article = Article.find_by(id: article_id)

    if article.nil?
      logger.info "ArticleThumbnailJob skip: article #{article_id} not found"
      return
    end

    if article.thumbnail.attached?
      if force
        article.thumbnail.purge
        logger.info "ArticleThumbnailJob purged existing thumbnail for article #{article_id} (force)"
      else
        logger.info "ArticleThumbnailJob skip: article #{article_id} already has thumbnail"
        return
      end
    end

    if article.is_youtube?
      attach_youtube_thumbnail(article)
    else
      generate_ai_thumbnail(article)
    end
  rescue ActiveRecord::RecordNotFound
    logger.info "ArticleThumbnailJob skip: article #{article_id} not found"
  end

  private

  # YouTube 썸네일 해상도 후보 (높은 순)
  YOUTUBE_THUMBNAIL_QUALITIES = %w[maxresdefault sddefault hqdefault mqdefault default].freeze

  #: (Article article) -> void
  def attach_youtube_thumbnail(article)
    video_id = article.youtube_id
    if video_id.blank?
      logger.info "ArticleThumbnailJob skip: article #{article.id} has no youtube_id"
      return
    end

    response = fetch_youtube_thumbnail(video_id)
    if response.nil?
      logger.warn "ArticleThumbnailJob failed: no youtube thumbnail for article #{article.id}"
      return
    end

    article.thumbnail.attach(
      io: StringIO.new(response.body),
      filename: "thumbnail-#{article.id}.jpg",
      content_type: response.headers["content-type"] || "image/jpeg"
    )
    logger.info "ArticleThumbnailJob attached youtube thumbnail for article #{article.id}"
  end

  #: (String video_id) -> Faraday::Response?
  def fetch_youtube_thumbnail(video_id)
    YOUTUBE_THUMBNAIL_QUALITIES.each do |quality|
      url = "https://img.youtube.com/vi/#{video_id}/#{quality}.jpg"
      response = Faraday.get(url)
      # YouTube는 존재하지 않는 해상도에 120x90 placeholder를 반환하므로 크기로 판별
      return response if response.success? && response.body.bytesize > 5_000
    end
    nil
  end

  #: (Article article) -> void
  def generate_ai_thumbnail(article)
    summary_key = article.summary_key
    if summary_key.blank? || !summary_key.is_a?(Array) || summary_key.empty?
      logger.info "ArticleThumbnailJob skip: article #{article.id} has no summary_key"
      return
    end

    prompt = build_prompt(summary_key)
    message = ArticleImageAgent.new.ask(prompt)

    attachment = extract_image_attachment(message.content)
    if attachment.nil?
      logger.warn "ArticleThumbnailJob failed: no image generated for article #{article.id} (content=#{message.content.inspect.truncate(200)})"
      return
    end

    ext = MIME::Types[attachment.mime_type].first&.preferred_extension || "png"
    article.thumbnail.attach(
      io: StringIO.new(attachment.content),
      filename: "thumbnail-#{article.id}.#{ext}",
      content_type: attachment.mime_type
    )
    logger.info "ArticleThumbnailJob attached ai thumbnail for article #{article.id}"
  end

  #: (untyped content) -> RubyLLM::Attachment?
  def extract_image_attachment(content)
    return nil unless content.respond_to?(:attachments)

    content.attachments.find(&:image?) || content.attachments.first
  end

  #: (Array[String] summary_key) -> String
  def build_prompt(summary_key)
    points = summary_key.each_with_index.map { |s, i| "#{i + 1}. #{s}" }.join("\n")
    <<~PROMPT.strip
      다음은 기술 뉴스 기사의 핵심 요약이다. 이 요약을 인포그래픽 이미지 한 장으로 시각화한다.

      [요약]
      #{points}
    PROMPT
  end
end
