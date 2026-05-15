# frozen_string_literal: true
# rbs_inline: enabled

require "cgi"

class SlackArticlePresenter
  include ArticlePresentable

  #: (Article article) -> void
  def initialize(article)
    @article = article
  end

  #: () -> String
  def text
    [ escaped_title, escaped_summary, escaped_article_url ].compact.join(" - ")
  end

  #: () -> Array[Hash[Symbol, untyped]]
  def blocks
    blocks = [
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

    if (url = thumbnail_url)
      blocks << {
        type: "image",
        image_url: url,
        alt_text: escaped_title
      }
    end

    blocks
  end

  private

  def escaped_title
    CGI.escapeHTML(title)
  end

  def escaped_summary
    CGI.escapeHTML(summary.to_s)
  end

  def escaped_article_url
    CGI.escapeHTML(article_page_url)
  end
end
