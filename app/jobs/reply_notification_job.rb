# frozen_string_literal: true

# rbs_inline: enabled

class ReplyNotificationJob < ApplicationJob
  queue_as :default

  #: (Integer parent_comment_id, Integer reply_comment_id) -> void
  def perform(parent_comment_id, reply_comment_id)
    parent_comment = Comment.includes(:user, :article).find(parent_comment_id)
    reply_comment = Comment.includes(:user).find(reply_comment_id)

    return if parent_comment.user.nil?
    return if parent_comment.user_id == reply_comment.user_id

    PushNotificationService.new.notify_user(
      user: parent_comment.user,
      title: "내 댓글에 새 답글이 달렸습니다",
      body: build_body(reply_comment),
      path: notification_path(parent_comment)
    )
  end

  private

  def build_body(reply_comment)
    "#{reply_comment.author_name}: #{reply_comment.body.to_s.truncate(80)}"
  end

  def notification_path(parent_comment)
    Rails.application.routes.url_helpers.article_path(
      parent_comment.article,
      anchor: "comment_#{parent_comment.id}"
    )
  end
end
