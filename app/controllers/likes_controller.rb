# frozen_string_literal: true

class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_likeable

  LIKEABLE_CLASSES = {
    "Post" => Post,
    "Article" => Article
  }.freeze

  def create
    current_user.like!(@likeable)
    @likeable.reload

    respond_to do |format|
      format.turbo_stream { render Views::Likes::ToggleTurboStream.new(likeable: @likeable) }
      format.html { redirect_back fallback_location: fallback_location }
    end
  end

  def destroy
    current_user.unlike!(@likeable)
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

    likeable_id = params.require(:"#{likeable_class.model_name.singular}_id")
    @likeable = find_likeable(likeable_class, likeable_id)
  end

  def fallback_location
    feed_path
  end

  def find_likeable(likeable_class, likeable_id)
    if likeable_class.respond_to?(:friendly)
      likeable_class.friendly.find(likeable_id)
    else
      likeable_class.find(likeable_id)
    end
  end
end
