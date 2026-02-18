# frozen_string_literal: true

class Components::Comments::CommentHeader < Components::Base
  include PhlexIcons

  def initialize(comments:)
    @comments = comments
  end

  def view_template
    Hero::ChatBubbleOvalLeftEllipsis(variant: :outline, class: "w-6 h-6 mr-2 text-blue-500")
    plain "댓글"
    span(class: "ml-2 px-2 py-1 bg-blue-600 text-white text-sm rounded-full") { @comments.size.to_s }
  end
end
