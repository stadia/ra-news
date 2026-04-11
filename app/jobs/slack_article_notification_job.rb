# frozen_string_literal: true

class SlackArticleNotificationJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find(article_id)
    SlackArticleNotifierService.new.call(article)
  end
end
