# frozen_string_literal: true

require "test_helper"

class UserWorkspaceSubscriptionTest < ActiveSupport::TestCase
  test "사용자와 워크스페이스 조합은 유일해야 한다" do
    duplicate = UserWorkspaceSubscription.new(
      user: users(:john),
      slack_workspace: slack_workspaces(:acme),
      slack_user_id: "UOTHER",
      channel_id: "COTHER",
      channel_name: "other",
      active: true
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "이미 존재하는 값입니다"
  end

  test "활성 구독은 채널 정보가 필요하다" do
    subscription = UserWorkspaceSubscription.new(
      user: users(:john),
      slack_workspace: slack_workspaces(:globex),
      slack_user_id: "UJOHN2",
      channel_id: nil,
      channel_name: nil,
      active: true
    )

    assert_not subscription.valid?
    assert_includes subscription.errors[:channel_id], "내용을 입력해 주세요"
    assert_includes subscription.errors[:channel_name], "내용을 입력해 주세요"
  end
end
