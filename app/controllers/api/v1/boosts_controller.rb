# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class Api::V1::BoostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_boostable

  skip_before_action :verify_authenticity_token, if: :json_request?, only: [ :create, :destroy ]

  BOOSTABLE_CLASSES = {
    "Post" => Post,
    "Article" => Article
  }.freeze

  def create
    current_user.boost!(@boostable)
    @boostable.reload

    respond_to do |format|
      format.turbo_stream { render Views::Boosts::ToggleTurboStream.new(boostable: @boostable) }
      format.html { redirect_back fallback_location: fallback_location }
      format.json { render json: boost_status_json, status: :created }
    end
  end

  def destroy
    current_user.unboost!(@boostable)
    @boostable.reload

    respond_to do |format|
      format.turbo_stream { render Views::Boosts::ToggleTurboStream.new(boostable: @boostable) }
      format.html { redirect_back fallback_location: fallback_location }
      format.json { render json: boost_status_json, status: :ok }
    end
  end

  private

  def set_boostable
    boostable_class = BOOSTABLE_CLASSES[params.require(:boostable_type)]
    head(:unprocessable_entity) and return unless boostable_class

    boostable_id = params.require(:"#{boostable_class.model_name.singular}_id")
    @boostable = find_boostable(boostable_class, boostable_id)
  end

  def fallback_location
    feed_path
  end

  def boost_status_json
    {
      boostable_type: @boostable.class.name,
      boostable_slug: @boostable.slug,
      boosted: current_user.boosts?(@boostable),
      boosts_count: @boostable.boosts_count
    }
  end

  def find_boostable(boostable_class, boostable_id)
    scope = boostable_class.respond_to?(:kept) ? boostable_class.kept : boostable_class
    if scope.respond_to?(:friendly)
      scope.friendly.find(boostable_id)
    else
      scope.find(boostable_id)
    end
  end
end
