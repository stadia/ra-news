# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# 웹 UI(부스트 버튼)의 turbo_stream 토글. JSON 응답은 Api::V1::BoostsController가 맡는다.
class BoostsController < ApplicationController
  before_action :set_boostable

  def create
    current_user.boost!(@boostable)
    @boostable.reload

    respond_to do |format|
      format.turbo_stream { render Views::Boosts::ToggleTurboStream.new(boostable: @boostable) }
      format.html { redirect_back fallback_location: feed_path }
    end
  end

  def destroy
    current_user.unboost!(@boostable)
    @boostable.reload

    respond_to do |format|
      format.turbo_stream { render Views::Boosts::ToggleTurboStream.new(boostable: @boostable) }
      format.html { redirect_back fallback_location: feed_path }
    end
  end

  private

  def set_boostable
    @boostable = Reactions::TargetLookup.find(type: params[:boostable_type], params: params, kept_only: true)
    head :unprocessable_entity if @boostable.nil?
  end
end
