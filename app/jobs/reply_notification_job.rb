# frozen_string_literal: true

# rbs_inline: enabled

class ReplyNotificationJob < ApplicationJob
  queue_as :default

  #: (Integer parent_comment_id, Integer reply_comment_id) -> void
  def perform(parent_comment_id, reply_comment_id)
    parent_comment = Comment.includes(:user, :article).find(parent_comment_id)
    reply_comment = Comment.includes(:user).find(reply_comment_id)

    if parent_comment.user.nil?
      logger.info "ReplyNotificationJob skip: parent comment #{parent_comment_id} has no user"
      return
    end
    if parent_comment.user_id == reply_comment.user_id
      logger.info "ReplyNotificationJob skip: self-reply by user #{parent_comment.user_id}"
      return
    end

    logger.info "ReplyNotificationJob start: reply #{reply_comment_id} → parent #{parent_comment_id} (notify user #{parent_comment.user_id})"
    notify_reply(parent_comment:, reply_comment:)
  end

  private

  def notify_reply(parent_comment:, reply_comment:)
    result = PushNotificationService.new.call(
      user: parent_comment.user,
      title: "내 댓글에 새 답글이 달렸습니다",
      body: build_body(reply_comment),
      path: notification_path(parent_comment)
    )

    return if result.success?

    logger.info "ReplyNotificationJob skipped push delivery for comment #{reply_comment.id}: #{result.failure}"
  end

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
