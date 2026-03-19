# app/controllers/actors_controller.rb
# frozen_string_literal: true

class ActorsController < ApplicationController
  include Pundit::Authorization

  allow_unauthenticated_access
  before_action :resume_session
  after_action :verify_authorized

  def show
    @actor = Federails::Actor.find_param(params[:id])
    authorize @actor, policy_class: Federails::Client::ActorPolicy
    render_show
  end

  def lookup
    @actor = Federails::Actor.find_by_account(params.require(:account).strip)
    raise ActiveRecord::RecordNotFound if @actor.nil?
    authorize @actor, policy_class: Federails::Client::ActorPolicy
    render_show
  end

  private

  def render_show
    respond_to do |format|
      if @actor.tombstoned?
        format.html { render Views::Actors::Gone.new, status: :gone }
        format.turbo_stream { render Views::Actors::Gone.new, status: :gone }
        format.json { render json: { error: "Gone" }, status: :gone }
      else
        format.html { render Views::Actors::Show.new(actor: @actor) }
        format.turbo_stream { render Views::Actors::Show.new(actor: @actor) }
        format.json { render json: actor_json }
      end
    end
  end

  def actor_json
    {
      id: @actor.id,
      username: @actor.username,
      name: @actor.name,
      federated_url: @actor.federated_url,
      at_address: @actor.at_address,
      profile_url: @actor.profile_url,
      local: @actor.local?
    }
  end

  def pundit_user
    Current.user
  end
end
