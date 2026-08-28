# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class Api::V1::BoostsController < Api::V1::BaseController
  before_action :set_boostable

  def create
    current_user.boost!(@boostable)
    @boostable.reload

    render json: boost_status_json, status: :created
  end

  def destroy
    current_user.unboost!(@boostable)
    @boostable.reload

    render json: boost_status_json, status: :ok
  end

  private

  def set_boostable
    @boostable = Reactions::TargetLookup.find(type: params[:boostable_type], params: params, kept_only: true)
    head :unprocessable_entity if @boostable.nil?
  end

  def boost_status_json
    {
      boostable_type: @boostable.class.name,
      boostable_slug: @boostable.slug,
      boosted: current_user.boosts?(@boostable),
      boosts_count: @boostable.boosts_count
    }
  end
end
