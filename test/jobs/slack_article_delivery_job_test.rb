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
end
