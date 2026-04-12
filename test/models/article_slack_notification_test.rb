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

  test "관련 없는 기사는 slack notification job을 enqueue 하지 않는다" do
    assert_no_enqueued_jobs only: SlackArticleNotificationJob do
      Article.create!(
        title: "관련 없는 기사",
        title_ko: "관련 없는 기사 번역",
        url: "https://example.com/unrelated-slack-article",
        origin_url: "https://example.com/unrelated-slack-article",
        host: "example.com",
        slug: "unrelated-slack-article",
        published_at: Time.current,
        is_related: false,
        user: users(:john)
      )
    end
  end

  test "article이 unrelated에서 related로 바뀌면 slack notification job을 enqueue 한다" do
    article = articles(:site_only_article)
    article.update!(title_ko: "관련 없는 기사 번역")

    clear_enqueued_jobs

    assert_enqueued_with(job: SlackArticleNotificationJob, args: [ article.id ]) do
      article.update!(is_related: true)
    end
  end
end
