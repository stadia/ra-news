# frozen_string_literal: true
# rbs_inline: enabled

class DiscordArticlePresenter
  include Rails.application.routes.url_helpers

  #: (Article article) -> void
  def initialize(article)
    @article = article
  end

  #: () -> Hash[Symbol, untyped]
  def embed_params
    {
      title: title,
      url: article_url(@article),
      description: summary&.truncate(200),
      color: 3447003,
      image_url: nil,
      footer_text: "AlNews",
      timestamp: @article.created_at
    }
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
end
