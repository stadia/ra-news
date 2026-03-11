# frozen_string_literal: true

class Components::Articles::ArticleUser < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  attr_reader :article

  def initialize(article:)
    @article = article
  end

  def view_template
    if article.site
      if (uri = safe_url(article.site.base_uri))
        link_to(article.user_name, uri, target: "_blank", rel: "noopener noreferrer")
      else
        plain article.user_name
      end
    else
      plain article.user_name
    end
  end
end
