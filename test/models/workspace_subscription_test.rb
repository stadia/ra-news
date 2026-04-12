# frozen_string_literal: true

require "test_helper"

class WorkspaceSubscriptionTest < ActiveSupport::TestCase
  test "사용자와 워크스페이스 조합은 유일해야 한다" do
    duplicate = WorkspaceSubscription.new(
      user: users(:john),
      slack_workspace: slack_workspaces(:acme),
      slack_user_id: "UOTHER",
      channel_id: "COTHER",
      channel_name: "other",
      active: true
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:user_id, :taken)
  end

  test "활성 구독은 채널 정보가 필요하다" do
    subscription = WorkspaceSubscription.new(
      user: users(:john),
      slack_workspace: slack_workspaces(:globex),
      slack_user_id: "UJOHN2",
      channel_id: nil,
      channel_name: nil,
      active: true
    )

    assert_not subscription.valid?
    assert subscription.errors.of_kind?(:channel_id, :blank)
    assert subscription.errors.of_kind?(:channel_name, :blank)
  end
end
