# frozen_string_literal: true

# rbs_inline: enabled

class BlueskyPostJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  BlueskyConfig = Struct.new(:character_limit, :shortened_url_length, :formatting_buffer) do
    def max_content_length
      character_limit - shortened_url_length - formatting_buffer
    end
  end

  BLUESKY_CONFIG = BlueskyConfig.new(300, 23, 4)

  #: (Integer id) -> void
  def perform(id)
    article = Article.kept.find_by(id: id)
    logger.info "BlueskyPostJob started for article id: #{id}"

    unless article
      logger.error "Article with id #{id} not found or has been discarded."
      return
    end

    # Skip posting if article is not Ruby-related or lacks required content
    unless should_post_article?(article)
      logger.info "Skipping Bluesky post for article id: #{id} - not suitable for posting"
      return
    end

    begin
      post_to_bluesky(article)
      logger.info "Successfully posted article id: #{id} to Bluesky"
    rescue StandardError => e
      logger.error "Failed to post article id: #{id} to Bluesky: #{e.message}"
      Honeybadger.notify(e, context: { article_id: id, article_url: article.url })
    end
  end

  private

  #: (Article article) -> bool
  def should_post_article?(article)
    # Only post Ruby-related articles with proper content
    article.is_related && article.slug.present? && article.title_ko.present?
  end

  #: (Article article) -> void
  def post_to_bluesky(article)
    post_text = build_post_text(article)
    response = bluesky_client.post(post_text, langs: ['ko', 'en'])

    logger.info "Successfully posted to Bluesky for article id: #{article.id} - Response: #{response}"
  end

  #: (Article article) -> String
  def build_post_text(article)
    title = article.title_ko.presence || article.title
    summary = article.summary_key&.first.presence || "새로운 Ruby 관련 글이 올라왔습니다."
    content = "#{title}\n#{summary}"
    truncated_content = truncate_for_bluesky(content)
    article_link = article_url(article.slug)
    "#{truncated_content}\n#{article_link}"
  end

  #: (String content) -> String
  def truncate_for_bluesky(content)
    content.truncate(BLUESKY_CONFIG.max_content_length, omission: "...")
  end

  def bluesky_client #: -> BlueskyClient
    BlueskyClient.new
  end
end