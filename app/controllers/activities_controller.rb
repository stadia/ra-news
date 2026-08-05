# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class ActivitiesController < ApplicationController
  include Pundit::Authorization

  after_action :verify_authorized

  def index
    authorize Federails::Activity, policy_class: Federails::Client::ActivityPolicy
    @activities = policy_scope(Federails::Activity, policy_scope_class: Federails::Client::ActivityPolicy::Scope).all
    @activities = @activities.where(actor: Federails::Actor.find_param(params[:actor_id])) if params[:actor_id]
    render template: "federails/client/activities/index"
  end

  private

  def pundit_user
    current_user
  end
end
