# frozen_string_literal: true

# rbs_inline: enabled

class TwitterPostJob < ApplicationJob
  queue_as :default

  # Twitter constants
  TWITTER_CHARACTER_LIMIT = 280
  TWITTER_SHORTENED_URL_LENGTH = 23  # Twitter shortens all URLs to this length
  FORMATTING_BUFFER = 4  # For newlines and spacing ("\n\n" before summary and URL)

  #: (Integer id) -> void
  def perform(id)
    article = Article.kept.find_by(id: id)
    logger.info "TwitterPostJob started for article id: #{id}"
    
    unless article
      logger.error "Article with id #{id} not found or has been discarded."
      return
    end

    # Skip posting if article is not Ruby-related or lacks required content
    unless should_post_article?(article)
      logger.info "Skipping Twitter post for article id: #{id} - not suitable for posting"
      return
    end

    begin
      post_to_twitter(article)
      logger.info "Successfully posted article id: #{id} to Twitter"
    rescue StandardError => e
      logger.error "Failed to post article id: #{id} to Twitter: #{e.message}"
      Honeybadger.notify(e, context: { article_id: id, article_url: article.url })
    end
  end

  private

  #: (Article article) -> bool
  def should_post_article?(article)
    # Only post Ruby-related articles with proper content
    article.is_related &&
      article.title_ko.present? &&
      article.summary_key.present? &&
      article.url.present?
  end

  #: (Article article) -> void
  def post_to_twitter(article)
    # Create the tweet content
    tweet_text = build_tweet_text(article)
    
    # Post to Twitter using the X gem
    client = X::Client.new
    response = client.post("tweets", { text: tweet_text }.to_json)
    
    # Validate API response
    unless response.status.success?
      raise "Twitter API error: #{response.status} - #{response.body}"
    end
    
    logger.info "Successfully posted to Twitter for article id: #{article.id} - Status: #{response.status}"
  end

  #: (Article article) -> String
  def build_tweet_text(article)
    # Get the Korean title or fallback to original title
    title = article.title_ko.presence || article.title
    
    # Get first summary key point
    summary = article.summary_key&.first.presence || "새로운 Ruby 관련 글이 올라왔습니다."
    
    # Build the tweet with title, summary, and URL
    # Twitter shortens all URLs to exactly 23 characters regardless of original length
    content = "#{title}\n\n#{summary}"
    
    # Calculate maximum length for content (excluding URL and formatting)
    max_content_length = TWITTER_CHARACTER_LIMIT - TWITTER_SHORTENED_URL_LENGTH - FORMATTING_BUFFER
    
    # Truncate content if needed using Active Support's truncate method
    if content.length > max_content_length
      content = content.truncate(max_content_length, omission: "...")
    end
    
    "#{content}\n\n#{article.url}"
  end
end