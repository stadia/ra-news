# frozen_string_literal: true

class CommentReplyFormComponent < ViewComponent::Base
  def initialize(article:, comment:, parent_comment:, visible: false)
    @article = article
    @comment = comment
    @parent_comment = parent_comment
    @visible = visible
  end

  def frame_classes
    @visible ? "" : "hidden"
  end
end
