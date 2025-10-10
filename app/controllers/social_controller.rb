# frozen_string_literal: true

# rbs_inline: enabled

class SocialController < ApplicationController
  # provider OAuth2 인증 시작
  def provider_authorize #: () -> void
    oauth_config = Preference.get_object("#{provider}_oauth")
    client = OauthClientService.call(oauth_config)

    # PKCE 사용 (X.com OAuth2.0 요구사항)
    code_verifier = SecureRandom.urlsafe_base64(32)

    session["#{provider}_code_verifier"] = code_verifier

    authorize_url = authorize_url(client, code_verifier)

    session["#{provider}_state"] = authorize_url.match(/state=([^&]+)/)[1]

    redirect_to authorize_url, allow_other_host: true
  end

  # provider OAuth2 콜백 처리
  def provider_callback #: () -> void
    # State 검증
    if params[:state] != session["#{provider}_state".to_sym]
      redirect_to madmin_social_index_path, alert: "OAuth state 불일치 에러"
      nil
    end

    oauth_config = Preference.get_object("#{provider}_oauth")
    client = OauthClientService.call(oauth_config)

    begin
      token = client.auth_code.get_token(
        params[:code],
        redirect_uri: social_provider_callback_url(provider: provider),
        code_verifier: session["#{provider}_code_verifier"]
      )

      # Access token을 기존 oauth preference에 저장
      oauth_preference = Preference.get_object("#{provider}_oauth")
      current_config = oauth_preference.value || {}

      oauth_preference.value = current_config.merge(
        access_token: token.token,
        refresh_token: token.refresh_token,
        expires_at: token.expires_at,
        token_created_at: Time.current.to_i
      )
      oauth_preference.save!

      session.delete("#{provider}_code_verifier")
      session.delete("#{provider}_oauth_state")

      redirect_to madmin_social_index_path, notice: "OAuth 인증 성공! Access token이 저장되었습니다."
    rescue OAuth2::Error => e
      redirect_to madmin_social_index_path, alert: "OAuth 에러: #{e.message}"
    end
  end

  private

  def provider
    params[:provider].presence || "xcom"
  end

  def authorize_url(client, code_verifier)
    scope = case provider
    when "xcom"
      "tweet.read tweet.write users.read offline.access"
    when "mastodon"
      "read:statuses write:statuses"
    end

    code_challenge = Base64.urlsafe_encode64(
      Digest::SHA256.digest(code_verifier),
      padding: false
    )

    client.auth_code.authorize_url(
      redirect_uri: social_provider_callback_url(provider: provider),
      scope: scope,
      code_challenge: code_challenge,
      code_challenge_method: "S256",
      state: SecureRandom.hex(16)
    )
  end
end
