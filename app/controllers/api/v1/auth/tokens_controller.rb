# frozen_string_literal: true
# rbs_inline: enabled

class Api::V1::Auth::TokensController < Api::V1::BaseController
  skip_before_action :authenticate_user!

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
