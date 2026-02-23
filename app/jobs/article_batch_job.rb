# frozen_string_literal: true

# rbs_inline: enabled

class ArticleBatchJob < ApplicationJob
  queue_as :default

  #: (?Time created_at) -> void
  def perform(created_at = Time.zone.now.beginning_of_day)
    index_now_urls = []

    Article.kept.where(title_ko: nil, created_at: created_at...).limit(5).each do |article|
      begin
        result = ArticleAgentsService.new.call(article)
        index_now_urls << article_public_url(article) if result.success? && article.title_ko.present?
      rescue StandardError => e
        logger.error("Error processing article #{article.id}: #{e.message}")
      end
      sleep 1
    end

    ping_index_now(index_now_urls.uniq)

    # Rebuild search index only for kept articles
    PgSearch::Multisearch.rebuild(Article, clean_up: false, transactional: false)
  end

  private

  #: (Article article) -> String
  def article_public_url(article)
    Rails.application.routes.url_helpers.article_url(
      article.slug.presence || article.id,
      host: "ruby-news.kr",
      protocol: "https"
    )
  end

  #: (Array[String] urls) -> void
  def ping_index_now(urls)
    return if urls.blank?

    key = "187d5ed120cc45f8869b89302011d43a"
    host = "ruby-news.kr"
    key_location = "https://#{host}/#{key}.txt"
    config = { host:, key:, key_location: }
    return if config[:key].blank?

    payload = {
      host: config[:host],
      key: config[:key],
      keyLocation: config[:key_location],
      urlList: urls
    }

    response = Faraday.post("https://api.indexnow.org/IndexNow", payload.to_json, {
      "Content-Type" => "application/json; charset=utf-8"
    })

    if response.status.to_i.between?(200, 299)
      logger.info("IndexNow ping success: #{urls.size} urls")
    else
      logger.error("IndexNow ping failed: status=#{response.status}, body=#{response.body}")
    end
  rescue StandardError => e
    logger.error("IndexNow ping error: #{e.class} - #{e.message}")
  end
end
