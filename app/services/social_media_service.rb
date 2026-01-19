# frozen_string_literal: true

# rbs_inline: enabled

class SocialMediaService < Dry::Operation
  include Rails.application.routes.url_helpers

  #: (Article article, Symbol command) -> void
  def call(article, command: :post) #: void
    case command
    when :post
      step should_post_article?(article)
      step post_to_platform(article)
    when :delete
      step delete_from_platform(article)
    else
      raise ArgumentError, "Unknown command: #{command}. Use :post or :delete"
    end
  end

  protected

  #: (Article article) -> String
  def base_content(article)
    title = article.title_ko.presence || article.title
    summary = article.summary_key&.first.presence || "새로운 Ruby 관련 글이 올라왔습니다."
    { title: title, summary: summary }
  end

  def logger
    Rails.logger
  end

  private

  #: (Article article) -> bool
  def should_post_article?(article)
    # Only post Ruby-related articles with proper content
    if article.is_related && article.slug.present? && article.title_ko.present?
      Success(true)
    else
      logger.info "Skipping #{platform_name} post for article id: #{article.id} - not suitable for posting"
      Failure(:not_suitable)
    end
  end

  #: (String slug) -> String
  def article_link(slug)
    article_url(slug, host: "https://ruby-news.kr")
  end

  # 서브클래스에서 구현해야 하는 추상 메서드들
  #: (Article article) -> Dry::Monads::Result
  def post_to_platform(article)
    raise NotImplementedError, "Subclass must implement post_to_platform"
  end

  #: (Article article) -> Dry::Monads::Result
  def delete_from_platform(article)
    raise NotImplementedError, "Subclass must implement delete_from_platform"
  end

  #: (Article article) -> String
  def build_post_text(article)
    raise NotImplementedError, "Subclass must implement build_post_text"
  end

  def platform_name #: String
    raise NotImplementedError, "Subclass must implement platform_name"
  end

  def platform_client
    raise NotImplementedError, "Subclass must implement platform_client"
  end
end
