# frozen_string_literal: true

# rbs_inline: enabled

class SocialMediaService < ApplicationService
  include Rails.application.routes.url_helpers

  attr_reader :article #: Article

  #: (Article article) -> void
  def initialize(article)
    @article = article
  end

  def call #: void
    unless should_post_article?(article)
      logger.info "Skipping #{platform_name} post for article id: #{article.id} - not suitable for posting"
      return
    end

    begin
      post_to_platform(article)
    rescue StandardError => e
      logger.error "Failed to post article id: #{article.id} to #{platform_name}: #{e.message}"
      Honeybadger.notify(e, context: { article_id: article.id, article_url: article.url })
    end
  end

  private

  #: (Article article) -> bool
  def should_post_article?(article)
    # Only post Ruby-related articles with proper content
    article.is_related && article.slug.present? && article.title_ko.present?
  end

  #: (Article article) -> String
  def base_content(article)
    title = article.title_ko.presence || article.title
    summary = article.summary_key&.first.presence || "새로운 Ruby 관련 글이 올라왔습니다."
    { title: title, summary: summary }
  end

  #: () -> String
  def article_link
    article_url(article.slug, host: "https://ruby-news.kr")
  end

  # 서브클래스에서 구현해야 하는 추상 메서드들
  #: (Article article) -> void
  def post_to_platform(article)
    raise NotImplementedError, "Subclass must implement post_to_platform"
  end

  #: (Article article) -> String
  def build_post_text(article)
    raise NotImplementedError, "Subclass must implement build_post_text"
  end

  #: () -> String
  def platform_name
    raise NotImplementedError, "Subclass must implement platform_name"
  end

  def platform_client
    raise NotImplementedError, "Subclass must implement platform_client"
  end
end
