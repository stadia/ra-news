# frozen_string_literal: true

# rbs_inline: enabled

class ArticleAgentsService < OperationService
  #: (Article article) -> Dry::Monads::Result
  def call(article)
    step ensure_body(article)
    step run_agents(article)
    step run_embed(article)
  end

  private

  def ensure_body(article)
    return Success(article) if article.body.present? && article.body.size >= 25

    body_result = ContentService.new.call(article)
    if body_result.failure?
      article.discard!
      return Failure(body_result.failure)
    end

    article.update(body: body_result.value!)
    Success(article)
  end

  def run_agents(article)
    # result = Articles::OneShotAgent.call(
    #   raw_content: article.body,
    #   title: article.title,
    #   url: article.url,
    #   content_type: article.is_youtube? ? "youtube" : "html"
    # )
    result = ArticlePipeline.call(raw_content: article.body, title: article.title, url: article.url, content_type: article.is_youtube? ? "youtube" : "html")
    logger.info "Response received for article id: #{article.id}"

    logger.info "article id: #{article.id} status: #{result.status}"
    if result.status.blank? || result.status.to_sym != :success
      article.discard
      return Failure(:invalid_status)
    end

    # JSON 데이터 저장
    article.tag_list.add(result.content.delete(:tags).map { it.downcase }.uniq) if result.content[:tags].present?

    if result.content[:summary_body].present?
      result.content[:summary_body] = result.content[:summary_body]
        .gsub("\\n", "\n")
        .gsub("\\t", "\t")
        .gsub("\\r", "\r")
        .gsub("\\\\", "\\")
        .gsub('\"', '"')
    end

    article.update!(result.content)

    article.discard if result.content[:is_related] == false && %w[hacker_news rss gmail rss_page].include?(article.site&.client)
    Success(article)
  end

  def run_embed(article)
    return Success(article) if article.embedding.present?

    # Generate embeddings if not present and body exists
    begin
      embedded_body = RubyLLM.embed(
        article.body,
        model: "gemini-embedding-001", # Google's model
        dimensions: 1536 # 1536차원
      )
      article.update_column(:embedding, embedded_body.vectors.to_a) # Skip callbacks for performance
      Success(article)
    rescue StandardError => e
      logger.error "Failed to generate embeddings for article #{article.id}: #{e.message}"
      Failure(:embedding_failed)
    end
  end
end
