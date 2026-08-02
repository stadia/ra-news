# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class DiscordArticleDeliveryJob < ApplicationJob
  queue_as :default

  #: (Integer article_id, Integer channel_id) -> void
  def perform(article_id, channel_id)
    article = Article.find(article_id)
    channel = DiscordChannel.find(channel_id)

    raise ArgumentError, "DiscordChannel##{channel_id} is missing required fields" unless channel.webhook_url.present? && channel.channel_id.present? && channel.channel_name.present?

    DiscordDeliveryService.new.call(article, channel)
  end
end
