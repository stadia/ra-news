# frozen_string_literal: true

require "test_helper"

class ReplyNotificationJobTest < ActiveSupport::TestCase
  setup do
    @article = articles(:ruby_article)
    @parent_post = Post.create!(body: "부모 댓글", user: users(:john), article: @article)
  end

  teardown do
    @parent_post&.destroy
  end

  test "답글 작성자가 부모 댓글 작성자와 다르면 푸시 발송을 시도한다" do
    reply_post = Post.create!(
      body: "테스트 답글",
      user: users(:jane),
      article: @article,
      parent: @parent_post
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
      ReplyNotificationJob.perform_now(@parent_post.id, reply_post.id)
    end

    assert called
    assert_equal expected_user, captured[:user]
    assert_equal "내 댓글에 새 답글이 달렸습니다", captured[:title]
    assert_includes captured[:body], "테스트 답글"
    assert_includes captured[:path], "/articles/"
    assert_includes captured[:path], "#post_#{@parent_post.id}"
  ensure
    reply_post&.destroy
  end

  test "푸시 본문에서 HTML 태그를 제거하고 평문으로 전달한다" do
    reply_post = Post.create!(
      body: %(<p><a href="https://ruby-news.dev/@jeff" class="u-url mention">@jeff</a> 안녕하세요</p>),
      user: users(:jane),
      article: @article,
      parent: @parent_post
    )

    captured = {}
    success_result = Struct.new(:success?, :failure).new(true, nil)
    fake_service = Object.new
    fake_service.define_singleton_method(:call) do |**kwargs|
      captured[:body] = kwargs[:body]
      success_result
    end

    PushNotificationService.stub(:new, -> { fake_service }) do
      ReplyNotificationJob.perform_now(@parent_post.id, reply_post.id)
    end

    assert_includes captured[:body], "@jeff 안녕하세요"
    refute_includes captured[:body], "<"
    refute_includes captured[:body], "href"
  ensure
    reply_post&.destroy
  end

  test "답글 작성자가 부모 댓글 작성자와 같으면 발송하지 않는다" do
    reply_post = Post.create!(
      body: "내가 단 답글",
      user: users(:john),
      article: @article,
      parent: @parent_post
    )

    fake_service = Object.new
    fake_service.define_singleton_method(:call) do |**_args|
      raise "should not be called"
    end

    assert_nothing_raised do
      PushNotificationService.stub(:new, -> { fake_service }) do
        ReplyNotificationJob.perform_now(@parent_post.id, reply_post.id)
      end
    end
  ensure
    reply_post&.destroy
  end
end
