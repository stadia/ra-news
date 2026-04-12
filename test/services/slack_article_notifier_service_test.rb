# frozen_string_literal: true

require "test_helper"

class SlackArticleNotifierServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @article = articles(:ruby_article)
    WorkspaceSubscription.delete_all
    SlackArticleDelivery.where(article: @article).delete_all

    WorkspaceSubscription.create!(
      user: users(:john),
      slack_workspace: slack_workspaces(:acme),
      slack_user_id: "UJOHN1",
      channel_id: "CNEWS1",
      channel_name: "ruby-news",
      active: true
    )
    WorkspaceSubscription.create!(
      user: users(:jane),
      slack_workspace: slack_workspaces(:acme),
      slack_user_id: "UJANE1",
      channel_id: "CNEWS1",
      channel_name: "ruby-news",
      active: true
    )
    WorkspaceSubscription.create!(
      user: users(:jane),
      slack_workspace: slack_workspaces(:globex),
      slack_user_id: "UJANE2",
      channel_id: "CNEWS2",
      channel_name: "team-ruby",
      active: true
    )
  end

  test "채널 기준으로 중복 없이 기사 알림 잡을 enqueue한다" do
    assert_enqueued_jobs 2, only: SlackArticleDeliveryJob do
      SlackArticleNotifierService.new.call(@article)
    end

    enqueued = enqueued_jobs.select { |j| j[:job] == SlackArticleDeliveryJob }
    channel_ids = enqueued.map { |j| j[:args][2] }.sort

    assert_equal %w[CNEWS1 CNEWS2], channel_ids
  end

  test "같은 기사에 대해 두 번 호출해도 각 채널마다 잡이 enqueue된다" do
    # 중복 방지는 SlackArticleDeliveryJob 내부의 with_lock으로 처리됨
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

  test "관련 없는 기사는 발송하지 않는다" do
    article = articles(:site_only_article)
    article.update!(title_ko: "관련 없는 기사 번역")

    assert_no_enqueued_jobs only: SlackArticleDeliveryJob do
      SlackArticleNotifierService.new.call(article)
    end
  end
end
