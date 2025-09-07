# frozen_string_literal: true

# rbs_inline: enabled

class TwitterService < ApplicationService
  include Rails.application.routes.url_helpers

  attr_reader :article #: Article

  TwitterConfig = Struct.new(:character_limit, :shortened_url_length, :formatting_buffer) do
    def max_content_length
      character_limit - shortened_url_length - formatting_buffer
    end
  end

  TWITTER_CONFIG = TwitterConfig.new(280, 23, 4) #: TwitterConfig

  #: (Article article) -> TwitterService
  def initialize(article)
    @article = article
  end

  def call #: void
    # Skip posting if article is not Ruby-related or lacks required content
    unless should_post_article?(article)
      logger.info "Skipping Twitter post for article id: #{article.id} - not suitable for posting"
      return
    end

    begin
      post_to_twitter(article)
      logger.info "Successfully posted article id: #{article.id} to Twitter"
    rescue StandardError => e
      logger.error "Failed to post article id: #{article.id} to Twitter: #{e.message}"
      Honeybadger.notify(e, context: { article_id: article.id, article_url: article.url })
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

    # 태그와 링크를 먼저 생성해서 길이 계산 (taggings_count가 가장 높은 태그 하나만)
    top_tag = article.tags.select { |it| it.is_confirmed? }.max_by(&:taggings_count)
    tags = top_tag ? "##{top_tag.name.gsub(/\s+/, '_').downcase}" : ""
    article_link = article_url(article.slug)

    # 태그와 링크를 위한 공간 확보 (공백 문자들 포함)
    reserved_space = tags.length + article_link.length + 3 # " " + "\n" + 여분
    available_content_length = TWITTER_CONFIG.character_limit - TWITTER_CONFIG.shortened_url_length - TWITTER_CONFIG.formatting_buffer - reserved_space

    truncated_content = content.truncate([ available_content_length, 1 ].max, omission: "...")
    "#{truncated_content} #{tags}\n#{article_link}"
  end

  #: (String content) -> String
  def truncate_for_twitter(content)
    content.truncate(TWITTER_CONFIG.max_content_length, omission: "...")
  end

  def twitter_client #: X::Client
    TwitterClient.new
  end
end
