# frozen_string_literal: true

# rbs_inline: enabled

# Slack OAuth 인증 정보를 저장하는 모델
class SlackCredential < ApplicationRecord
  belongs_to :user

  encrypts :access_token
  encrypts :refresh_token, deterministic: false

  validates :access_token, presence: { message: "액세스 토큰을 입력해주세요" }
  validates :team_id, presence: { message: "팀 ID를 입력해주세요" }
  validates :team_name, presence: { message: "팀 이름을 입력해주세요" }

  # 토큰 만료 확인
  def expired? #: () -> bool
    return false if expires_at.nil?

    expires_at < Time.current
  end

  # 토큰 갱신 필요 여부 (만료 1시간 전)
  def needs_refresh? #: () -> bool
    return false if expires_at.nil?

    expires_at < 1.hour.from_now
  end

  # 유효한 액세스 토큰 가져오기 (필요시 자동 갱신)
  def valid_access_token #: () -> String?
    return access_token unless needs_refresh?
    return access_token if refresh_token.blank?

    refresh_access_token
    access_token
  end

  private

  def refresh_access_token #: () -> void
    oauth_config = Preference.get_object("slack_oauth")
    client = OauthClientService.call(oauth_config)

    new_token = client.auth_code.get_token(
      refresh_token,
      grant_type: "refresh_token"
    )

    update!(
      access_token: new_token.token,
      refresh_token: new_token.refresh_token || refresh_token,
      expires_at: new_token.expires_at ? Time.at(new_token.expires_at) : nil,
      token_created_at: Time.current
    )
  rescue OAuth2::Error => e
    Rails.logger.error("Slack token refresh failed: #{e.message}")
    nil
  end
end
