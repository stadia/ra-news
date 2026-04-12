# frozen_string_literal: true

class SlackArticlePresenter
  include Rails.application.routes.url_helpers

  def initialize(article)
    @article = article
  end

  def text
    [ title, summary, article_url ].compact.join(" - ")
  end

  def blocks
    [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "*#{title}*\n#{summary}"
        }
      },
      {
        type: "context",
        elements: [
          {
            type: "mrkdwn",
            text: "<#{article_url}|기사 읽기> · #{published_label}"
          }
        ]
      }
    ]
  end

  private

  attr_reader :article

  def title
    article.title_ko.presence || article.title
  end

  def summary
    value = article.summary_key
    summary_text = value.is_a?(Array) ? value.first : value
    summary_text.presence || "요약이 없습니다."
  end

  def article_url
    Rails.application.routes.url_helpers.article_url(article)
  end

  def published_label
    I18n.l(article.published_at || Time.current, format: :short)
  end
end
