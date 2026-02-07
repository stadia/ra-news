# frozen_string_literal: true

class RecentCommentsSidebarComponent < ViewComponent::Base
  def initialize(recent_comments:)
    @recent_comments = recent_comments
  end
end
