# frozen_string_literal: true

class SlackWorkspacePolicy
  attr_reader :user, :workspace

  def initialize(user, workspace)
    @user = user
    @workspace = workspace
  end

  def create?
    subscribed_user?
  end

  def update?
    subscribed_user?
  end

  def destroy?
    subscribed_user?
  end

  def channels?
    subscribed_user?
  end

  private

  def subscribed_user?
    user.present? && user.workspace_subscriptions.exists?(slack_workspace: workspace)
  end
end
