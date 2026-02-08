# frozen_string_literal: true

class CommentFormComponent < ViewComponent::Base
  def initialize(article:, comment:)
    @article = article
    @comment = comment
  end
end
