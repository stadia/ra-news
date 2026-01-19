# frozen_string_literal: true

# rbs_inline: enabled

class ArticleBatchJob < ApplicationJob
  queue_as :default

  #: (?Time created_at) -> void
  def perform(created_at = Time.zone.now.beginning_of_day)
    Article.kept.where(title_ko: nil, created_at: created_at...).find_each do |article|
      begin
        ArticleLlmService.call(article)
      rescue StandardError => e
        logger.error("Error processing article #{article.id}: #{e.message}")
      end
      sleep 1
    end

    # Rebuild search index only for kept articles
    PgSearch::Multisearch.rebuild(Article, clean_up: false, transactional: false)
  end
end
