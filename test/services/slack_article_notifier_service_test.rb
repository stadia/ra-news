# frozen_string_literal: true

require "test_helper"

class SlackArticleNotifierServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @article = articles(:ruby_article)
    SlackArticleDelivery.where(article: @article).delete_all
  end

  test "workspace 기준으로 기사 알림 잡을 enqueue한다" do
    assert_enqueued_jobs 2, only: SlackArticleDeliveryJob do
      SlackArticleNotifierService.new.call(@article)
    end

    enqueued = enqueued_jobs.select { |j| j[:job] == SlackArticleDeliveryJob }
    workspace_ids = enqueued.map { |j| j[:args][1] }.sort

    assert_equal SlackWorkspace.delivery_ready.order(:id).pluck(:id), workspace_ids
  end

  test "같은 기사에 대해 두 번 호출해도 각 workspace마다 잡이 enqueue된다" do
    assert_enqueued_jobs 4, only: SlackArticleDeliveryJob do
      service = SlackArticleNotifierService.new
      service.call(@article)
      service.call(@article)
    end
  end

  test "confirmed 되지 않은 기사는 발송하지 않는다" do
    article = articles(:site_only_article)

    assert_no_enqueued_jobs only: SlackArticleDeliveryJob do
      SlackArticleNotifierService.new.call(article)
    end
  end
end
