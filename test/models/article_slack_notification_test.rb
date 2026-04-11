# frozen_string_literal: true

require "test_helper"

class ArticleSlackNotificationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "confirmed article 생성 시 slack notification job을 enqueue 한다" do
    assert_enqueued_with(job: SlackArticleNotificationJob) do
      Article.create!(
        title: "새 기사",
        title_ko: "새 기사 번역",
        url: "https://example.com/new-slack-article",
        origin_url: "https://example.com/new-slack-article",
        host: "example.com",
        slug: "new-slack-article",
        published_at: Time.current,
        is_related: true,
        user: users(:john)
      )
    end
  end

  test "article이 confirmed 상태로 바뀌면 slack notification job을 enqueue 한다" do
    article = Article.create!(
      title: "미확정 기사",
      url: "https://example.com/unconfirmed-slack-article",
      origin_url: "https://example.com/unconfirmed-slack-article",
      host: "example.com",
      published_at: Time.current,
      is_related: true,
      user: users(:john)
    )

    clear_enqueued_jobs

    assert_enqueued_with(job: SlackArticleNotificationJob, args: [ article.id ]) do
      article.update!(title_ko: "확정 기사", slug: "confirmed-slack-article")
    end
  end
end
