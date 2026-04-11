# frozen_string_literal: true

class SlackArticleNotificationJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find_by(id: article_id)
    return unless article

    SlackArticleNotifierService.new.call(article)
  end
end
