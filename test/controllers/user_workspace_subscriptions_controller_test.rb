# frozen_string_literal: true

require "test_helper"

class UserWorkspaceSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "POST create_or_update stores workspace channel selection for current user" do
    sign_in_as(users(:john))

    assert_difference("UserWorkspaceSubscription.count", 1) do
      post slack_workspace_subscription_path(slack_workspaces(:globex)), params: {
        user_workspace_subscription: {
          slack_user_id: "UJOHN-GLOBEX",
          channel_id: "CNEW123",
          channel_name: "alerts"
        }
      }
    end

    assert_redirected_to edit_user_registration_path

    subscription = UserWorkspaceSubscription.find_by!(user: users(:john), slack_workspace: slack_workspaces(:globex))
    assert_equal "CNEW123", subscription.channel_id
    assert_equal "alerts", subscription.channel_name
    assert_equal "UJOHN-GLOBEX", subscription.slack_user_id
  end

  test "PATCH create_or_update updates existing subscription" do
    sign_in_as(users(:john))

    patch slack_workspace_subscription_path(slack_workspaces(:acme)), params: {
      user_workspace_subscription: {
        slack_user_id: "UJOHN1",
        channel_id: "CUPDATED",
        channel_name: "updated-news"
      }
    }

    assert_redirected_to edit_user_registration_path

    subscription = user_workspace_subscriptions(:john_acme).reload
    assert_equal "CUPDATED", subscription.channel_id
    assert_equal "updated-news", subscription.channel_name
  end

  test "DELETE destroy deactivates subscription" do
    sign_in_as(users(:john))

    delete slack_workspace_subscription_path(slack_workspaces(:acme))

    assert_redirected_to edit_user_registration_path
    assert_not user_workspace_subscriptions(:john_acme).reload.active?
  end
end
