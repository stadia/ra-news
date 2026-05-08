# frozen_string_literal: true

class Api::V1::Auth::TokensController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, raise: false
  respond_to :json

  rescue_from ActionController::ParameterMissing do
    render json: { error: "missing_refresh_token" }, status: :bad_request
  end

  def refresh
    raw = params.require(:refresh_token)
    record = RefreshToken.find_active_by_raw(raw)

    return render(json: { error: "invalid_refresh_token" }, status: :unauthorized) unless record

    user = record.user
    record.revoke!
    _new_record, new_raw = RefreshToken.issue(user)
    access_token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

    render json: {
      access_token: access_token,
      refresh_token: new_raw,
      expires_in: 15.minutes.to_i
    }
  end
end
