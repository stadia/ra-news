# frozen_string_literal: true

class LoginRequiredComponent < ViewComponent::Base
  def initialize(title: "로그인이 필요합니다", message: "댓글을 작성하거나 대화에 참여하려면 로그인이 필요합니다.")
    @title = title
    @message = message
  end
end
