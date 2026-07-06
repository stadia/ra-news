# frozen_string_literal: true
# rbs_inline: enabled

class RefreshToken < ApplicationRecord
  REFRESH_TTL = 30.days

  belongs_to :user

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue(user)
    raw = SecureRandom.urlsafe_base64(64)
    record = create!(
      user: user,
      token_digest: digest(raw),
      expires_at: REFRESH_TTL.from_now
    )
    [ record, raw ]
  end

  def self.find_active_by_raw(raw)
    return nil if raw.blank?

    active.find_by(token_digest: digest(raw))
  end

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
