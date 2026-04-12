# frozen_string_literal: true

require "test_helper"

class WorkspaceSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "GET channels returns channel list for connected workspace" do
    sign_in_as(users(:john))

    channels = [
      { "id" => "CNEWS1", "name" => "ruby-news" },
      { "id" => "CNEWS2", "name" => "alerts" }
    ]
    client = Struct.new(:channels) do
      def list_channels
        channels
      end
    end

    SlackClient.stub(:new, client.new(channels)) do
      get channels_slack_workspace_subscription_path(slack_workspaces(:acme), format: :json)
    end

    assert_response :success
    assert_equal channels, response.parsed_body["channels"]
  end

  test "GET channels returns forbidden for unconnected workspace" do
    sign_in_as(users(:john))

    get channels_slack_workspace_subscription_path(slack_workspaces(:globex), format: :json)

    assert_response :forbidden
    assert_equal "접근 권한이 없습니다.", response.parsed_body["error"]
  end

  test "POST create_or_update stores workspace channel selection for current user" do
    sign_in_as(users(:john))
    WorkspaceSubscription.create!(
      user: users(:john),
      slack_workspace: slack_workspaces(:globex),
      slack_user_id: "UJOHN2",
      active: false
    )

    assert_no_difference("WorkspaceSubscription.count") do
      post slack_workspace_subscription_path(slack_workspaces(:globex)), params: {
        workspace_subscription: {
          channel_id: "CNEW123",
          channel_name: "alerts"
        }
      }
    end

    assert_redirected_to edit_user_registration_path

    subscription = WorkspaceSubscription.find_by!(user: users(:john), slack_workspace: slack_workspaces(:globex))

    assert_equal "CNEW123", subscription.channel_id
    assert_equal "alerts", subscription.channel_name
  end

  test "PATCH create_or_update updates existing subscription" do
    sign_in_as(users(:john))

      patch slack_workspace_subscription_path(slack_workspaces(:acme)), params: {
      workspace_subscription: {
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
