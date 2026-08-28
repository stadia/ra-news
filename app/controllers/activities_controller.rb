# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class ActivitiesController < ApplicationController
  include Pundit::Authorization

  after_action :verify_authorized

  def index
    authorize Fedipub::Activity, policy_class: Fedipub::Client::ActivityPolicy
    @activities = policy_scope(Fedipub::Activity, policy_scope_class: Fedipub::Client::ActivityPolicy::Scope).all
    @activities = @activities.where(actor: Fedipub::Actor.find_param(params[:actor_id])) if params[:actor_id]
    render template: "fedipub/client/activities/index"
  end

  private

  def pundit_user
    current_user
  end
end
