# frozen_string_literal: true
# rbs_inline: enabled

class ReplyNotificationJob < ApplicationJob
  queue_as :default

  #: (Integer parent_post_id, Integer reply_post_id) -> void
  def perform(parent_post_id, reply_post_id)
    parent_post = Post.includes(:user, :article).find(parent_post_id)
    reply_post = Post.includes(:user).find(reply_post_id)

    if parent_post.user.nil?
      logger.info "ReplyNotificationJob skip: parent post #{parent_post_id} has no user"
      return
    end
    if parent_post.user_id == reply_post.user_id
      logger.info "ReplyNotificationJob skip: self-reply by user #{parent_post.user_id}"
      return
    end

    logger.info "ReplyNotificationJob start: reply #{reply_post_id} → parent #{parent_post_id} (notify user #{parent_post.user_id})"
    notify_reply(parent_post:, reply_post:)
  end

  private

  def notify_reply(parent_post:, reply_post:)
    result = PushNotificationService.new.call(
      user: parent_post.user,
      title: "내 댓글에 새 답글이 달렸습니다",
      body: build_body(reply_post),
      path: notification_path(parent_post)
    )

    return if result.success?

    logger.info "ReplyNotificationJob skipped push delivery for post #{reply_post.id}: #{result.failure}"
  end

  def build_body(reply_post)
    "#{reply_post.author_name}: #{reply_post.body.to_s.truncate(80)}"
  end

  def notification_path(parent_post)
    if parent_post.article.present?
      Rails.application.routes.url_helpers.article_path(
        parent_post.article,
        anchor: "post_#{parent_post.id}"
      )
    else
      Rails.application.routes.url_helpers.post_path(parent_post)
    end
  end
end
