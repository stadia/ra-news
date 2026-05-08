# frozen_string_literal: true

require "test_helper"

class RefreshTokenTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
  end

  test "issue returns record and raw token, stores digest only" do
    record, raw = RefreshToken.issue(@user)

    assert raw.is_a?(String)
    assert_operator raw.length, :>=, 64
    assert_not_equal raw, record.token_digest
    assert_equal Digest::SHA256.hexdigest(raw), record.token_digest
    assert_equal @user, record.user
    assert_in_delta RefreshToken::REFRESH_TTL.from_now, record.expires_at, 5
  end

  test "active scope excludes revoked and expired" do
    fresh, _raw = RefreshToken.issue(@user)
    revoked, _raw = RefreshToken.issue(@user)
    revoked.update!(revoked_at: Time.current)
    expired, _raw = RefreshToken.issue(@user)
    expired.update_columns(expires_at: 1.day.ago)

    assert_includes RefreshToken.active, fresh
    assert_not_includes RefreshToken.active, revoked
    assert_not_includes RefreshToken.active, expired
  end

  test "find_active_by_raw matches valid raw token" do
    record, raw = RefreshToken.issue(@user)

    assert_equal record, RefreshToken.find_active_by_raw(raw)
    assert_nil RefreshToken.find_active_by_raw("nope")
  end

  test "find_active_by_raw rejects revoked token" do
    record, raw = RefreshToken.issue(@user)
    record.revoke!

    assert_nil RefreshToken.find_active_by_raw(raw)
  end

  test "revoke! sets revoked_at" do
    record, _raw = RefreshToken.issue(@user)

    assert_nil record.revoked_at
    record.revoke!
    assert_not_nil record.reload.revoked_at
  end
end
