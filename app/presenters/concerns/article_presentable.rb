# frozen_string_literal: true
# rbs_inline: enabled

module ArticlePresentable
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  private

  attr_reader :article #: Article

  #: () -> String
  def title
    article.title_ko.presence || article.title.to_s
  end

  #: () -> String?
  def summary
    value = article.summary_key
    summary_text = value.is_a?(Array) ? value.first : value
    summary_text.presence || article.base_content[:summary]
  end

  #: () -> String
  def site_name
    article.site&.name.presence || article.host.to_s
  end

  #: () -> String
  def published_label
    I18n.l(article.published_at || Time.current, format: :short)
  end

  #: () -> String
  def article_page_url
    Rails.application.routes.url_helpers.article_url(article)
  end
end
