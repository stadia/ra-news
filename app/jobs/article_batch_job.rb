# frozen_string_literal: true
# rbs_inline: enabled

class ArticleBatchJob < ApplicationJob
  include JobRateLimiting

  queue_as :default

  #: (?Time created_at) -> void
  def perform(created_at = Time.zone.now.beginning_of_day)
    index_now_urls = []
    reload = false

    Article.kept.where(title_ko: nil, created_at: created_at...).limit(5).each do |article|
      unless check_rate_limit
        logger.warn("ArticleBatchJob: rate limit reached, stopping batch early")
        break
      end

      begin
        result = ArticleAgentsService.new.call(article)
        index_now_urls << article_public_url(article) if result.success? && article.title_ko.present?
        reload = true
      rescue StandardError => e
        logger.error("Error processing article #{article.id}: #{e.message}")
      end
      sleep 1
    end

    return unless reload

    ping_index_now(index_now_urls.uniq)
  end

  private

  def rate_limit_threshold #: Integer
    1
  end

  def rate_limit_window #: ActiveSupport::Duration
    5.minutes
  end

  #: (Article article) -> String
  def article_public_url(article)
    Rails.application.routes.url_helpers.article_url(
      article,
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
