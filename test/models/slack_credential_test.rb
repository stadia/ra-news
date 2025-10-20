# frozen_string_literal: true

require "test_helper"

class SlackCredentialTest < ActiveSupport::TestCase
  def setup
    @user = users(:john)
    @credential = SlackCredential.new(
      user: @user,
      access_token: "xoxb-test-token",
      refresh_token: "xoxe-test-refresh",
      expires_at: 1.hour.from_now,
      token_created_at: Time.current,
      team_id: "T123456",
      team_name: "Test Team"
    )
  end

  # ========== Validation Tests ==========

  test "유효한 속성을 가진 경우 유효해야 한다" do
    assert @credential.valid?
  end

  test "access_token은 필수 항목이어야 한다" do
    @credential.access_token = nil
    assert_not @credential.valid?
    assert_includes @credential.errors[:access_token], "액세스 토큰을 입력해주세요"
  end

  test "team_id는 필수 항목이어야 한다" do
    @credential.team_id = nil
    assert_not @credential.valid?
    assert_includes @credential.errors[:team_id], "팀 ID를 입력해주세요"
  end

  test "team_name은 필수 항목이어야 한다" do
    @credential.team_name = nil
    assert_not @credential.valid?
    assert_includes @credential.errors[:team_name], "팀 이름을 입력해주세요"
  end

  # ========== Association Tests ==========

  test "user와 연관되어야 한다" do
    assert_respond_to @credential, :user
    assert_equal @user, @credential.user
  end

  test "user가 삭제되면 함께 삭제되어야 한다" do
    @credential.save!
    assert_difference "SlackCredential.count", -1 do
      @user.destroy
    end
  end

  # ========== Token Expiration Tests ==========

  test "expired? - 만료되지 않은 토큰" do
    @credential.expires_at = 1.hour.from_now
    assert_not @credential.expired?
  end

  test "expired? - 만료된 토큰" do
    @credential.expires_at = 1.hour.ago
    assert @credential.expired?
  end

  test "expired? - expires_at이 nil인 경우" do
    @credential.expires_at = nil
    assert_not @credential.expired?
  end

  test "needs_refresh? - 갱신이 필요한 토큰 (1시간 이내 만료)" do
    @credential.expires_at = 30.minutes.from_now
    assert @credential.needs_refresh?
  end

  test "needs_refresh? - 갱신이 필요하지 않은 토큰" do
    @credential.expires_at = 2.hours.from_now
    assert_not @credential.needs_refresh?
  end

  test "needs_refresh? - expires_at이 nil인 경우" do
    @credential.expires_at = nil
    assert_not @credential.needs_refresh?
  end

  # ========== Encryption Tests ==========

  test "access_token은 암호화되어 저장되어야 한다" do
    @credential.save!

    # 데이터베이스에서 직접 읽은 값은 암호화되어 있어야 함
    raw_value = ActiveRecord::Base.connection.execute(
      "SELECT access_token FROM slack_credentials WHERE id = #{@credential.id}"
    ).first["access_token"]

    assert_not_equal "xoxb-test-token", raw_value

    # 모델을 통해 읽으면 복호화된 값을 반환
    assert_equal "xoxb-test-token", @credential.reload.access_token
  end

  test "refresh_token은 암호화되어 저장되어야 한다" do
    @credential.save!

    raw_value = ActiveRecord::Base.connection.execute(
      "SELECT refresh_token FROM slack_credentials WHERE id = #{@credential.id}"
    ).first["refresh_token"]

    assert_not_equal "xoxe-test-refresh", raw_value
    assert_equal "xoxe-test-refresh", @credential.reload.refresh_token
  end

  # ========== Uniqueness Tests ==========

  test "같은 user와 team_id 조합은 유일해야 한다" do
    @credential.save!

    duplicate = SlackCredential.new(
      user: @user,
      access_token: "xoxb-another-token",
      team_id: "T123456",
      team_name: "Test Team"
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate.save(validate: false)
    end
  end

  test "다른 team_id는 같은 user에게 허용되어야 한다" do
    @credential.save!

    another_team = SlackCredential.new(
      user: @user,
      access_token: "xoxb-another-token",
      team_id: "T789012",
      team_name: "Another Team"
    )

    assert another_team.valid?
    assert_difference "SlackCredential.count", 1 do
      another_team.save!
    end
  end
end
