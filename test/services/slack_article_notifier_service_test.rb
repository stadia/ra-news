# frozen_string_literal: true

require "test_helper"

class SlackArticleNotifierServiceTest < ActiveSupport::TestCase
  setup do
    @article = articles(:ruby_article)
    UserWorkspaceSubscription.delete_all
    SlackArticleDelivery.where(article: @article).delete_all

    UserWorkspaceSubscription.create!(
      user: users(:john),
      slack_workspace: slack_workspaces(:acme),
      slack_user_id: "UJOHN1",
      channel_id: "CNEWS1",
      channel_name: "ruby-news",
      active: true
    )
    UserWorkspaceSubscription.create!(
      user: users(:jane),
      slack_workspace: slack_workspaces(:acme),
      slack_user_id: "UJANE1",
      channel_id: "CNEWS1",
      channel_name: "ruby-news",
      active: true
    )
    UserWorkspaceSubscription.create!(
      user: users(:jane),
      slack_workspace: slack_workspaces(:globex),
      slack_user_id: "UJANE2",
      channel_id: "CNEWS2",
      channel_name: "team-ruby",
      active: true
    )
  end

  test "채널 기준으로 중복 없이 기사 알림을 발송한다" do
    sent_messages = []
    fake_client = Object.new
    fake_client.define_singleton_method(:post_message) do |channel:, text:, blocks:|
      sent_messages << { channel:, text:, blocks: }
      { "ok" => true, "ts" => "123.456" }
    end

    SlackClient.stub(:new, fake_client) do
      SlackArticleNotifierService.new.call(@article)
    end

    assert_equal %w[CNEWS1 CNEWS2], sent_messages.map { |message| message[:channel] }.sort
    assert_equal 2, SlackArticleDelivery.where(article: @article).count
  end

  test "이미 발송된 채널에는 다시 보내지 않는다" do
    sent_messages = []
    fake_client = Object.new
    fake_client.define_singleton_method(:post_message) do |channel:, text:, blocks:|
      sent_messages << { channel:, text:, blocks: }
      { "ok" => true, "ts" => "123.456" }
    end

    SlackClient.stub(:new, fake_client) do
      service = SlackArticleNotifierService.new
      service.call(@article)
      service.call(@article)
    end

    assert_equal 2, sent_messages.size
    assert_equal 2, SlackArticleDelivery.where(article: @article).count
  end

  test "confirmed 되지 않은 기사는 발송하지 않는다" do
    article = articles(:site_only_article)
    fake_client = Object.new
    fake_client.define_singleton_method(:post_message) do |**_kwargs|
      raise "should not post"
    end

    SlackClient.stub(:new, fake_client) do
      SlackArticleNotifierService.new.call(article)
    end

    assert_equal 0, SlackArticleDelivery.where(article: article).count
  end
end
