# frozen_string_literal: true

require "test_helper"

class ReplyNotificationJobTest < ActiveSupport::TestCase
  setup do
    @article = articles(:ruby_article)
    @parent_comment = comments(:root_comment_1)
  end

  test "답글 작성자가 부모 댓글 작성자와 다르면 푸시 발송을 시도한다" do
    reply_comment = Comment.create!(
      body: "테스트 답글",
      user: users(:jane),
      article: @article,
      parent_id: @parent_comment.id
    )

    called = false
    captured = {}
    expected_user = users(:john)
    fake_service = Object.new
    success_result = Struct.new(:success?, :failure).new(true, nil)
    fake_service.define_singleton_method(:call) do |**kwargs|
      called = true
      captured[:user] = kwargs[:user]
      captured[:title] = kwargs[:title]
      captured[:body] = kwargs[:body]
      captured[:path] = kwargs[:path]

      success_result
    end

    PushNotificationService.stub(:new, -> { fake_service }) do
      ReplyNotificationJob.perform_now(@parent_comment.id, reply_comment.id)
    end

    assert called
    assert_equal expected_user, captured[:user]
    assert_equal "내 댓글에 새 답글이 달렸습니다", captured[:title]
    assert_includes captured[:body], "테스트 답글"
    assert_includes captured[:path], "/articles/"
    assert_includes captured[:path], "#comment_#{@parent_comment.id}"
  end

  test "답글 작성자가 부모 댓글 작성자와 같으면 발송하지 않는다" do
    reply_comment = Comment.create!(
      body: "내가 단 답글",
      user: users(:john),
      article: @article,
      parent_id: @parent_comment.id
    )

    fake_service = Object.new
    fake_service.define_singleton_method(:call) do |**_args|
      raise "should not be called"
    end

    assert_nothing_raised do
      PushNotificationService.stub(:new, -> { fake_service }) do
        ReplyNotificationJob.perform_now(@parent_comment.id, reply_comment.id)
      end
    end
  end
end
