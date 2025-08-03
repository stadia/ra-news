# frozen_string_literal: true

class ArticleComponent < ViewComponent::Base
  def initialize(article:)
    @article = article
  end
end
