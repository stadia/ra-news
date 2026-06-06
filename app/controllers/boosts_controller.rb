# frozen_string_literal: true
# rbs_inline: enabled

class BoostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_boostable

  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }, only: [ :create, :destroy ]

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
    if boostable_class.respond_to?(:friendly)
      boostable_class.friendly.find(boostable_id)
    else
      boostable_class.find(boostable_id)
    end
  end
end
