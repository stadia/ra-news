# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class Api::V1::LikesController < Api::V1::BaseController
  before_action :set_likeable

  def create
    current_user.like!(@likeable)
    @likeable.reload

    render json: like_status_json, status: :created
  end

  def destroy
    current_user.unlike!(@likeable)
    @likeable.reload

    render json: like_status_json, status: :ok
  end

  private

  def set_likeable
    @likeable = Reactions::TargetLookup.find(type: params[:likeable_type], params: params)
    head :unprocessable_entity if @likeable.nil?
  end

  def like_status_json
    {
      likeable_type: @likeable.class.name,
      likeable_slug: @likeable.slug,
      liked: current_user.likes?(@likeable),
      likes_count: @likeable.likes_count
    }
  end
end
