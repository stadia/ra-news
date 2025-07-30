# frozen_string_literal: true

# rbs_inline: enabled

class TwitterPostJob < ApplicationJob
  queue_as :default

  #: (Integer id) -> void
  def perform(id)
    article = Article.kept.find_by(id: id)
    logger.info "TwitterPostJob started for article id: #{id}"
    
    unless article.is_a?(Article)
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
    article.is_related == true &&
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
    
    logger.info "Twitter API response for article id: #{article.id} - #{response.status}"
  end

  #: (Article article) -> String
  def build_tweet_text(article)
    # Get the Korean title or fallback to original title
    title = article.title_ko.presence || article.title
    
    # Get first summary key point
    summary = if article.summary_key.is_a?(Array) && article.summary_key.any?
                article.summary_key.first
              else
                "새로운 Ruby 관련 글이 올라왔습니다."
              end
    
    # Build the tweet with title, summary, and URL
    # Twitter has a 280 character limit, so we need to be careful
    base_text = "#{title}\n\n#{summary}\n\n#{article.url}"
    
    # Truncate if too long (leave room for URL which is auto-shortened by Twitter)
    if base_text.length > 280
      available_length = 280 - article.url.length - 4 # 4 for newlines and spacing
      truncated_content = "#{title}\n\n#{summary}"[0, available_length - 3] + "..."
      "#{truncated_content}\n\n#{article.url}"
    else
      base_text
    end
  end
end