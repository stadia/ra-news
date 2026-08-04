# typed: strict
# frozen_string_literal: true
# rbs_inline: enabled

class Api::V1::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "not_found" }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: "parameter_missing", parameter: e.param }, status: :bad_request
  end
end
