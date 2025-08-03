# frozen_string_literal: true

# rbs_inline: enabled

class TwitterPostJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  TwitterConfig = Struct.new(:character_limit, :shortened_url_length, :formatting_buffer) do
    def max_content_length
      character_limit - shortened_url_length - formatting_buffer
    end
  end

  TWITTER_CONFIG = TwitterConfig.new(280, 23, 4)

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
    article.is_related && article.slug.present? && article.title_ko.present?
  end

  #: (Article article) -> void
  def post_to_twitter(article)
    tweet_text = build_tweet_text(article)
    response = twitter_client.post(tweet_text)

    # Validate API response
    # unless response.status.success?
    #   raise "Twitter API error: #{response.status} - #{response.body}"
    # end

    logger.info "Successfully posted to Twitter for article id: #{article.id} - Status: #{response}"
  end

  #: (Article article) -> String
  def build_tweet_text(article)
    title = article.title_ko.presence || article.title
    summary = article.summary_key&.first.presence || "새로운 Ruby 관련 글이 올라왔습니다."
    content = "#{title}\n#{summary}"
    truncated_content = truncate_for_twitter(content)
    article_link = article_url(article.slug)
    "#{truncated_content}\n#{article_link}"
  end

  #: (String content) -> String
  def truncate_for_twitter(content)
    content.truncate(TWITTER_CONFIG.max_content_length, omission: "...")
  end

  def twitter_client #: -> X::Client
    TwitterClient.new
  end
end
