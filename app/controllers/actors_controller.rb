# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class ActorsController < ApplicationController
  include WebOnlyFormats
  # show는 respond_to로 ActivityPub JSON을 정식 제공한다.
  skip_before_action :ensure_web_format, only: %i[show]

  include Pundit::Authorization

  skip_before_action :authenticate_user!
  after_action :verify_authorized

  def show
    @actor = Fedipub::Actor.find_param(params[:id])
    authorize @actor, policy_class: Fedipub::Client::ActorPolicy
    render_show
  end

  def lookup
    account = params[:account]&.strip
    if account.blank?
      skip_authorization
      render Views::Actors::Lookup.new
      return
    end

    # find_by_account 는 실패 시 ActiveRecord::RecordNotFound 를 raise 하고 nil 을
    # 돌려주지 않는다. 예외는 그대로 404 로 올라간다.
    @actor = Fedipub::Actor.find_by_account(account)
    authorize @actor, policy_class: Fedipub::Client::ActorPolicy
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
    current_user
  end
end
