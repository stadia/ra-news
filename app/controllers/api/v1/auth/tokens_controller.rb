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

    user = nil
    new_raw = nil
    RefreshToken.transaction do
      record.lock!
      if record.revoked_at.present? || record.expires_at <= Time.current
        return render json: { error: "invalid_refresh_token" }, status: :unauthorized
      end

      user = record.user
      record.update!(revoked_at: Time.current)
      _new_record, new_raw = RefreshToken.issue(user)
    end

    access_token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

    render json: {
      access_token: access_token,
      refresh_token: new_raw,
      expires_in: Warden::JWTAuth.config.expiration_time.to_i
    }
  end
end
