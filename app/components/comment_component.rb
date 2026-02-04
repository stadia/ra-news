# frozen_string_literal: true

class CommentComponent < ViewComponent::Base
  def initialize(comment:, article:)
    @comment = comment
    @article = article
  end
end
