# frozen_string_literal: true

# rbs_inline: enabled

class ArticleJob < ApplicationJob
  queue_as :default

  #: (Integer id) -> void
  def perform(id)
    article = Article.kept.find_by(id: id)
    logger.info "ArticleJob started for article id: #{id}"

    unless article.is_a?(Article)
      logger.error "Article with id #{id} not found or has been discarded."
      return nil
    end

    ArticleLlmService.call(article)

    # Rebuild search index only for kept articles
    PgSearch::Multisearch.rebuild(Article, clean_up: false, transactional: false) if article.kept?
  end
end
