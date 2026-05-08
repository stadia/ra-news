# frozen_string_literal: true

class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_likeable

  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }, only: [ :create, :destroy ]

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
      format.json { render json: like_status_json, status: :created }
    end
  end

  def destroy
    current_user.unlike!(@likeable)
    @likeable.reload

    respond_to do |format|
      format.turbo_stream { render Views::Likes::ToggleTurboStream.new(likeable: @likeable) }
      format.html { redirect_back fallback_location: fallback_location }
      format.json { render json: like_status_json, status: :ok }
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

  def like_status_json
    {
      likeable_type: @likeable.class.name,
      likeable_slug: @likeable.slug,
      liked: current_user.likes?(@likeable),
      likes_count: @likeable.likes_count
    }
  end

  def find_likeable(likeable_class, likeable_id)
    if likeable_class.respond_to?(:friendly)
      likeable_class.friendly.find(likeable_id)
    else
      likeable_class.find(likeable_id)
    end
  end
end
