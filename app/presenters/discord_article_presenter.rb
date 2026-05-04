# frozen_string_literal: true
# rbs_inline: enabled

class DiscordArticlePresenter
  include ArticlePresentable

  DEFAULT_EMBED_COLOR = 3447003 #: Integer

  #: (Article article) -> void
  def initialize(article)
    @article = article
  end

  #: () -> Hash[Symbol, untyped]
  def embed_params
    {
      title: title,
      url: article_page_url,
      description: summary&.truncate(200),
      color: DEFAULT_EMBED_COLOR,
      image_url: nil,
      footer_text: site_name,
      timestamp: @article.created_at
    }
  end
end
