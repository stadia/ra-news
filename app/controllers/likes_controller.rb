# frozen_string_literal: true

class LikesController < ApplicationController
  before_action :require_authentication
  before_action :set_likeable

  LIKEABLE_CLASSES = {
    "Post" => Post
  }.freeze

  def create
    Current.user.like!(@likeable)
    @likeable.reload

    respond_to do |format|
      format.turbo_stream { render Views::Likes::ToggleTurboStream.new(likeable: @likeable) }
      format.html { redirect_back fallback_location: fallback_location }
    end
  end

  def destroy
    Current.user.unlike!(@likeable)
    @likeable.reload

    respond_to do |format|
      format.turbo_stream { render Views::Likes::ToggleTurboStream.new(likeable: @likeable) }
      format.html { redirect_back fallback_location: fallback_location }
    end
  end

  private

  def set_likeable
    likeable_class = LIKEABLE_CLASSES[params.require(:likeable_type)]
    head(:unprocessable_entity) and return unless likeable_class

    @likeable = likeable_class.find(params.require(:"#{likeable_class.model_name.singular}_id"))
  end

  def fallback_location
    feed_path
  end
end
