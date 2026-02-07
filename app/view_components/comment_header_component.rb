# frozen_string_literal: true

class CommentHeaderComponent < ViewComponent::Base
  def initialize(comments:)
    @comments = comments
  end
end
