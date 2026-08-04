# typed: strict
# frozen_string_literal: true

require "test_helper"

class DiscardedArticleCleanupJobTest < ActiveSupport::TestCase
  test "6개월이 지난 discarded article만 정리한다" do
    old_discarded_article = articles(:deleted_article)
    old_discarded_article.update_columns(created_at: 7.months.ago, deleted_at: 7.months.ago)

    recent_discarded_article = Article.new(
      title: "최근 삭제 기사",
      url: "https://example.com/recent-discarded-article",
      origin_url: "https://example.com/recent-discarded-article",
      user: users(:john),
      site: sites(:ruby_weekly)
    )
    recent_discarded_article.stub(:generate_metadata, nil) { recent_discarded_article.save! }
    recent_discarded_article.update_columns(deleted_at: 1.week.ago)

    old_kept_article = Article.new(
      title: "오래된 일반 기사",
      url: "https://example.com/old-kept-article",
      origin_url: "https://example.com/old-kept-article",
      user: users(:john),
      site: sites(:ruby_weekly)
    )
    old_kept_article.stub(:generate_metadata, nil) { old_kept_article.save! }
    old_kept_article.update_columns(created_at: 7.months.ago)

    comment = Post.create!(body: "정리 대상 댓글", user: users(:john), article: old_discarded_article)
    delivery = NotificationDelivery.create!(
      type: "SlackDelivery",
      article: old_discarded_article,
      notification_channel: notification_channels(:globex_slack),
      channel_id: "CLEANUP",
      channel_name: "cleanup",
      status: "sent"
    )

    DiscardedArticleCleanupJob.perform_now

    assert_not Article.exists?(old_discarded_article.id)
    assert Article.exists?(recent_discarded_article.id)
    assert Article.exists?(old_kept_article.id)
    assert_nil comment.reload.article_id
    assert_not NotificationDelivery.exists?(delivery.id)
  end
end
