# frozen_string_literal: true

require "test_helper"

class SlackArticleDeliveryJobTest < ActiveJob::TestCase
  test "전송 기록 저장에 실패하면 예외를 발생시켜 재시도 가능 상태로 남긴다" do
    article = articles(:ruby_article)
    workspace = slack_workspaces(:acme)
    delivery = SlackArticleDelivery.create!(
      article:,
      slack_workspace: workspace,
      channel_id: "CFAILED1",
      channel_name: "ruby-news",
      status: :failed
    )
    logger = Minitest::Mock.new

    logger.expect(:error, nil, [ String ])

    SlackClient.stub(:new, Struct.new(:response) {
      def post_message(channel:, text:, blocks:)
        response
      end
    }.new({ "ts" => "123.456" })) do
      Rails.stub(:logger, logger) do
        job = SlackArticleDeliveryJob.new
        job.stub(:persist_delivery_success, false) do
          error = assert_raises(ActiveRecord::RecordInvalid) do
            job.perform(article.id, workspace.id, delivery.channel_id, delivery.channel_name)
          end

          assert_equal delivery.id, error.record.id
        end
      end
    end

    logger.verify
  end

  test "전송 실패 처리 중 이미 sent 상태면 failed로 되돌리지 않는다" do
    article = articles(:ruby_article)
    workspace = slack_workspaces(:acme)
    delivery = SlackArticleDelivery.create!(
      article:,
      slack_workspace: workspace,
      channel_id: "CSENT1",
      channel_name: "ruby-news",
      status: :sent,
      sent_at: Time.current,
      slack_message_ts: "123.456"
    )

    SlackClient.stub(:new, Struct.new(:error) {
      def post_message(channel:, text:, blocks:)
        raise error
      end
    }.new(SlackClient::ApiError.new("timeout"))) do
      SlackArticleDeliveryJob.perform_now(article.id, workspace.id, delivery.channel_id, delivery.channel_name)
    end

    assert_predicate delivery.reload, :sent?
    assert_nil delivery.error_message
  end
end
