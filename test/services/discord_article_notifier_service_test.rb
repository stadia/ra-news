# frozen_string_literal: true

require "test_helper"

class DiscordArticleNotifierServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @article = articles(:ruby_article)
    DiscordDelivery.where(article: @article).delete_all
  end

  test "channel 기준으로 기사 알림 잡을 enqueue한다" do
    expected_count = DiscordChannel.delivery_ready.count
    assert_enqueued_jobs expected_count, only: DiscordArticleDeliveryJob do
      DiscordArticleNotifierService.new.call(@article)
    end

    enqueued = enqueued_jobs.select { |j| j[:job] == DiscordArticleDeliveryJob }
    channel_ids = enqueued.map { |j| j[:args][1] }.sort

    assert_equal DiscordChannel.delivery_ready.order(:id).pluck(:id), channel_ids
  end

  test "confirmed 되지 않은 기사는 발송하지 않는다" do
    article = articles(:site_only_article)

    assert_no_enqueued_jobs only: DiscordArticleDeliveryJob do
      DiscordArticleNotifierService.new.call(article)
    end
  end
end
