# frozen_string_literal: true

class CommentsComponent < ViewComponent::Base
  def initialize(article:, comments:)
    @article = article
    @comments = comments
  end
end
