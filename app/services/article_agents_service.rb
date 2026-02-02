# frozen_string_literal: true

# rbs_inline: enabled

class ArticleAgentsService < ApplicationService
  attr_reader :article #: Article

  #: (Article article) -> ArticleAgentsService
  def initialize(article)
    @article = article
  end

  def call #: void
    if article.body.blank? || article.body.size < 25
      body = ContentService.new.call(article)
      article.discard! and return if body.failure?

      article.update(body: body.value!)
    end

    result = ArticlePipeline.call(raw_content: article.body, title: article.title, url: article.url, content_type: article.is_youtube? ? "youtube" : "html")
    logger.info "Response received for article id: #{article.id}"

    # Generate embeddings if not present and body exists
    if article.embedding.blank? && article.body.present?
      begin
        embedded_body = RubyLLM.embed(
          article.body,
          model: "gemini-embedding-001", # Google's model
          dimensions: 1536 # 1536차원
        )
        article.update_column(:embedding, embedded_body.vectors.to_a) # Skip callbacks for performance
      rescue StandardError => e
        logger.error "Failed to generate embeddings for article #{article.id}: #{e.message}"
        # Continue processing without embeddings
      end
    end

    logger.info "article id: #{article.id} status: #{result.status}"
    if result.status.blank? || result.status != "success"
      article.discard
      return nil
    end

    # JSON 데이터 저장
    article.tag_list.add(result.steps[:knowledge].content[:global_context]["tags"].map { it.downcase }.uniq) if result.steps[:knowledge].content[:global_context]["tags"].present?
    # summary_detail에서 body 부분을 summary_body로 분리
    update_attrs = result.steps[:technical_writer].content
    update_attrs[:is_related] = result.content[:approved] == true
    # Update article attributes in single query
    article.update!(update_attrs)

    # 매직 스트링 대신 Site.clients enum 사용
    if result.content[:approved] == false && %w[hacker_news rss gmail rss_page].include?(article.site&.client)
      article.discard # `deleted_at = Time.zone.now` 대신 discard 사용
      nil # Exit early if discarded
    end
  end
end
