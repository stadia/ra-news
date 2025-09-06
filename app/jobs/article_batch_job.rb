# frozen_string_literal: true

# rbs_inline: enabled

class ArticleBatchJob < ApplicationJob
  queue_as :default

  #: (?Time created_at) -> void
  def perform(created_at = Time.zone.now.beginning_of_day)
    Article.kept.where(title_ko: nil, created_at: created_at...).find_each do |article|
      ArticleLlmService.call(article)
      sleep 1
    end
  end
end
