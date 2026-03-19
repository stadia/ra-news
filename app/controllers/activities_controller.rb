# app/controllers/activities_controller.rb
# frozen_string_literal: true

class ActivitiesController < ApplicationController
  include Pundit::Authorization

  after_action :verify_authorized

  private

  def pundit_user
    Current.user
  end

  public

  def index
    authorize Federails::Activity, policy_class: Federails::Client::ActivityPolicy
    @activities = policy_scope(Federails::Activity, policy_scope_class: Federails::Client::ActivityPolicy::Scope).all
    @activities = @activities.where(actor: Federails::Actor.find_param(params[:actor_id])) if params[:actor_id]
    render template: "federails/client/activities/index"
  end

  def feed
    authorize Federails::Activity, policy_class: Federails::Client::ActivityPolicy
    @activities = Federails::Activity.feed_for(Current.user.federails_actor)
    render template: "federails/client/activities/feed"
  end
end
