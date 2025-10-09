# frozen_string_literal: true

# rbs_inline: enabled

class MastodonService < ApplicationService
  include Rails.application.routes.url_helpers

  attr_reader :article #: Article

  MastodonConfig = Struct.new(:character_limit, :url_length_counted, :formatting_buffer) do
    def max_content_length
      character_limit - formatting_buffer
    end
  end

  # Mastodon의 기본 문자 제한은 500자 (인스턴스마다 다를 수 있음)
  # URL은 실제 길이가 카운트됨 (Twitter와 다름)
  MASTODON_CONFIG = MastodonConfig.new(500, true, 10) #: MastodonConfig

  #: (Article article) -> MastodonService
  def initialize(article)
    @article = article
  end

  def call #: void
    # Skip posting if article is not Ruby-related or lacks required content
    unless should_post_article?(article)
      logger.info "Skipping Mastodon post for article id: #{article.id} - not suitable for posting"
      return
    end

    begin
      post_to_mastodon(article)
      logger.info "Successfully posted article id: #{article.id} to Mastodon"
    rescue StandardError => e
      logger.error "Failed to post article id: #{article.id} to Mastodon: #{e.message}"
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
  def post_to_mastodon(article)
    toot_text = build_toot_text(article)
    response = mastodon_client.post(toot_text)
    logger.info "Successfully posted to Mastodon for article id: #{article.id} - Status: #{response}"
  end

  #: (Article article) -> String
  def build_toot_text(article)
    title = article.title_ko.presence || article.title
    summary = article.summary_key&.first.presence || "새로운 Ruby 관련 글이 올라왔습니다."
    content = "#{title}\n\n#{summary}"

    # Mastodon은 여러 태그를 지원하므로 상위 3개 태그 사용
    top_tags = article.tags.select { |it| it.is_confirmed? }
                           .sort_by(&:taggings_count)
                           .reverse
                           .take(3)
    tags = top_tags.map { |tag| "##{tag.name.gsub(/\s+/, '_').downcase}" }.join(" ")
    article_link = article_url(article.slug, host: "https://ruby-news.kr")

    # Mastodon은 URL을 실제 길이로 계산하므로 링크 길이도 포함
    reserved_space = tags.length + article_link.length + 5 # 공백과 줄바꿈
    available_content_length = MASTODON_CONFIG.character_limit - MASTODON_CONFIG.formatting_buffer - reserved_space

    truncated_content = content.truncate([ available_content_length, 1 ].max, omission: "...")
    "#{truncated_content}\n\n#{tags}\n#{article_link}"
  end

  #: (String content) -> String
  def truncate_for_mastodon(content)
    content.truncate(MASTODON_CONFIG.max_content_length, omission: "...")
  end

  def mastodon_client #: MastodonClient
    MastodonClient.new
  end
end
