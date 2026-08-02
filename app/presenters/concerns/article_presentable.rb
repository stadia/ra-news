# typed: false
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
    items = case value
    when Array
      value.compact_blank
    when String
      [ value ]
    else
      []
    end
    items = [ article.base_content[:summary] ] if items.empty?
    items.compact_blank!
    return nil if items.empty?

    items.map { |text| "• #{text}" }.join("\n")
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

  #: () -> String?
  def thumbnail_url
    return nil unless article.thumbnail.attached?

    Rails.application.routes.url_helpers.rails_blob_url(
      article.thumbnail,
      disposition: "inline"
    )
  end
end
