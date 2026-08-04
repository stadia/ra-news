# typed: true
# frozen_string_literal: true

require "test_helper"

class SlackArticleDeliveryJobTest < ActiveJob::TestCase
  setup do
    @article = articles(:ruby_article)
    @channel = notification_channels(:acme_slack)
  end

  test "존재하지 않는 article_id면 RecordNotFound 에러가 발생한다" do
    assert_raises(ActiveRecord::RecordNotFound) do
      SlackArticleDeliveryJob.new.perform(-1, @channel.id)
    end
  end

  test "존재하지 않는 channel_id면 RecordNotFound 에러가 발생한다" do
    assert_raises(ActiveRecord::RecordNotFound) do
      SlackArticleDeliveryJob.new.perform(@article.id, -1)
    end
  end

  test "channel 필수 필드가 누락되면 ArgumentError가 발생한다" do
    @channel.update_columns(webhook_url: "")

    assert_raises(ArgumentError) do
      SlackArticleDeliveryJob.new.perform(@article.id, @channel.id)
    end

    # teardown
    @channel.update_columns(webhook_url: "https://hooks.slack.com/services/EXAMPLE/REDACTED")
  end
end
