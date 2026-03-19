# frozen_string_literal: true

class Components::Comments::CommentHeader < Components::Base
  include PhlexIcons

  def initialize(comments:)
    @comments = comments
  end

  def view_template
    Hero::ChatBubbleOvalLeftEllipsis(variant: :outline, class: "w-6 h-6 mr-2 text-state-info")
    plain "댓글"
    render RubyUI::Badge.new(variant: :blue, class: "ml-2") { @comments.size.to_s }
  end
end
