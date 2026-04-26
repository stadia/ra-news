# frozen_string_literal: true
# rbs_inline: enabled

class SlackArticleDeliveryJob < ApplicationJob
  queue_as :default

  #: (Integer article_id, Integer channel_id) -> void
  def perform(article_id, channel_id)
    article = Article.find(article_id)
    channel = SlackChannel.find(channel_id)

    raise ArgumentError, "SlackChannel##{channel_id} is missing required fields" unless channel.webhook_url.present? && channel.channel_id.present? && channel.channel_name.present?

    SlackDeliveryService.new.call(article, channel)
  end
end
