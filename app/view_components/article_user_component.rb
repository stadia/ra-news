# frozen_string_literal: true

class ArticleUserComponent < ViewComponent::Base
  def initialize(article:)
    @article = article
  end
end
