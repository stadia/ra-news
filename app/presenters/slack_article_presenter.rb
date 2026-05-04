# frozen_string_literal: true
# rbs_inline: enabled

require "cgi"

class SlackArticlePresenter
  include Rails.application.routes.url_helpers

  def initialize(article)
    @article = article
  end

  def text
    [ escaped_title, escaped_summary, escaped_article_url ].compact.join(" - ")
  end

  def blocks
    [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "*<#{escaped_article_url}|#{escaped_title}>*\n#{escaped_summary}"
        }
      },
      {
        type: "context",
        elements: [
          {
            type: "mrkdwn",
            text: "#{site_name} · #{published_label}"
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
    summary_text.presence || article.base_content[:summary]
  end

  def article_url
    Rails.application.routes.url_helpers.article_url(article)
  end

  def escaped_title
    CGI.escapeHTML(title.to_s)
  end

  def escaped_summary
    CGI.escapeHTML(summary.to_s)
  end

  def escaped_article_url
    CGI.escapeHTML(article_url.to_s)
  end

  def published_label
    I18n.l(article.published_at || Time.current, format: :short)
  end

  def site_name
    article.site&.name.presence || article.host.to_s
  end
end
