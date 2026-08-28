# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# 웹 UI(좋아요 버튼)의 turbo_stream 토글. JSON 응답은 Api::V1::LikesController가 맡는다.
class LikesController < ApplicationController
  before_action :set_likeable

  def create
    current_user.like!(@likeable)
    @likeable.reload

    respond_to do |format|
      format.turbo_stream { render Views::Likes::ToggleTurboStream.new(likeable: @likeable) }
      format.html { redirect_back fallback_location: feed_path }
    end
  end

  def destroy
    current_user.unlike!(@likeable)
    @likeable.reload

    respond_to do |format|
      format.turbo_stream { render Views::Likes::ToggleTurboStream.new(likeable: @likeable) }
      format.html { redirect_back fallback_location: feed_path }
    end
  end

  private

  def set_likeable
    @likeable = Reactions::TargetLookup.find(type: params[:likeable_type], params: params)
    head :unprocessable_entity if @likeable.nil?
  end
end
