# frozen_string_literal: true

require "test_helper"

class SessionTest < ActiveSupport::TestCase
  # Test fixtures setup
  def setup
    @session = sessions(:john_session)
    @admin_session = sessions(:admin_session)
    @korean_session = sessions(:korean_session)
    @user = users(:john)
    @admin = users(:admin)
  end

  # ========== Validation Tests ==========

  test "유효한 속성을 가진 경우 유효해야 한다" do
    session = Session.new(
      user: @user,
      ip_address: "192.168.1.1",
      user_agent: "Test Browser"
    )
    assert session.valid?
  end

  test "user는 필수 항목이어야 한다" do
    session = Session.new(ip_address: "127.0.0.1", user_agent: "Test")
    assert_not session.valid?
    assert_includes session.errors[:user], "값이 반드시 필요합니다"
  end

  test "다른 사용자가 다른 세션을 가질 수 있도록 허용해야 한다" do
    session1 = Session.create!(user: @user, ip_address: "127.0.0.1", user_agent: "Browser 1")
    session2 = Session.create!(user: users(:jane), ip_address: "127.0.0.2", user_agent: "Browser 2")

    assert session1.valid?
    assert session2.valid?
    assert_not_equal session1.id, session2.id
  end

  # ========== Association Tests ==========

  test "user에 속해야 한다" do
    assert_respond_to @session, :user
    assert_kind_of User, @session.user
    assert_equal @user, @session.user
  end

  test "사용자가 삭제될 때 함께 삭제되어야 한다" do
    user = users(:minimal_user)
    initial_session_count = user.sessions.count
    session = Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "Test")

    # Expected to lose all sessions for this user (initial + 1 new)
    assert_difference "Session.count", -(initial_session_count + 1) do
      user.destroy!
    end

    assert_not Session.exists?(session.id)
  end

  test "사용자당 여러 세션을 허용해야 한다" do
    user = @user
    initial_session_count = user.sessions.count

    session1 = Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "Browser 1")
    session2 = Session.create!(user: user, ip_address: "127.0.0.2", user_agent: "Browser 2")
    session3 = Session.create!(user: user, ip_address: "127.0.0.3", user_agent: "Browser 3")

    user.reload
    assert_equal initial_session_count + 3, user.sessions.count
    assert_includes user.sessions, session1
    assert_includes user.sessions, session2
    assert_includes user.sessions, session3
  end

  # ========== Session Attributes Tests ==========

  test "자동 생성된 ID를 가져야 한다" do
    session = Session.create!(user: @user, ip_address: "127.0.0.1", user_agent: "Test")
    assert_not_nil session.id
    assert session.id > 0
  end

  test "IP 주소와 사용자 에이전트를 저장해야 한다" do
    ip = "192.168.1.100"
    agent = "Mozilla/5.0 (Test Browser)"

    session = Session.create!(
      user: @user,
      ip_address: ip,
      user_agent: agent
    )

    assert_equal ip, session.ip_address
    assert_equal agent, session.user_agent
  end

  test "nil IP 주소와 사용자 에이전트를 허용해야 한다" do
    session = Session.new(user: @user)
    assert session.valid?

    session.save!
    assert_nil session.ip_address
    assert_nil session.user_agent
  end

  # ========== Authentication Integration Tests ==========

  test "관리자 사용자와 함께 작동해야 한다" do
    admin = @admin
    admin_session = Session.create!(
      user: admin,
      ip_address: "127.0.0.1",
      user_agent: "Admin Browser"
    )

    assert admin_session.valid?
    assert admin_session.user.admin?
    assert_equal admin, admin_session.user
  end

  test "한국인 사용자와 함께 작동해야 한다" do
    korean_user = users(:korean_user)
    korean_session = Session.create!(
      user: korean_user,
      ip_address: "127.0.0.1",
      user_agent: "Korean Browser"
    )

    assert korean_session.valid?
    assert_equal korean_user, korean_session.user
    assert_equal "김철수", korean_session.user.name
  end

  test "한국어 이름을 가진 사용자의 세션 생성을 처리해야 한다" do
    korean_user = users(:user_with_spaces)
    session = Session.create!(
      user: korean_user,
      ip_address: "127.0.0.1",
      user_agent: "Spaces Browser"
    )

    assert session.valid?
    assert_equal "홍 길 동", session.user.name
  end

  # ========== Data Integrity Tests ==========

  test "참조 무결성을 유지해야 한다" do
    user = @user
    session = Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "Test")

    # Session should exist
    assert Session.exists?(session.id)
    assert_equal user, session.user

    # User should have the session
    assert_includes user.sessions, session
  end

  test "사용자 변경을 처리해야 한다" do
    session = @session
    original_user = session.user
    new_user = users(:jane)

    # Change user association
    session.user = new_user
    session.save!

    # Verify change
    session.reload
    assert_equal new_user, session.user
    assert_not_equal original_user, session.user

    # Original user should not have this session anymore
    original_user.reload
    assert_not_includes original_user.sessions, session

    # New user should have this session
    new_user.reload
    assert_includes new_user.sessions, session
  end

  # ========== Session Lifecycle Tests ==========

  test "적절한 타임스탬프로 세션을 생성해야 한다" do
    Time.zone = "Asia/Seoul"

    travel_to Time.zone.parse("2024-06-15 14:30:00") do
      session = Session.create!(
        user: @user,
        ip_address: "127.0.0.1",
        user_agent: "Test"
      )

      assert_kind_of ActiveSupport::TimeWithZone, session.created_at
      assert_kind_of ActiveSupport::TimeWithZone, session.updated_at
      assert_equal Time.zone.name, "Asia/Seoul"

      # Should be created at the current time
      expected_time = Time.zone.parse("2024-06-15 14:30:00")
      assert_equal expected_time.to_i, session.created_at.to_i
    end
  end

  test "변경 시 updated_at을 업데이트해야 한다" do
    session = @session
    original_updated_at = session.updated_at

    travel 1.hour do
      session.touch # Update the timestamp

      session.reload
      assert session.updated_at > original_updated_at
    end
  end

  # ========== Performance Tests ==========

  test "id로 세션을 효율적으로 찾아야 한다" do
    session_id = @session.id

    assert_queries(1) do
      found_session = Session.find(session_id)
      assert_equal @session, found_session
    end
  end

  test "user 연관 관계를 효율적으로 로드해야 한다" do
    session = @session

    # Loading user should not trigger additional query if already loaded
    session.user # Prime the association

    assert_queries(0) do
      user_name = session.user.name
      assert_not_nil user_name
    end
  end

  test "사용자로 세션을 효율적으로 찾아야 한다" do
    user = @user

    assert_queries(1) do
      sessions = user.sessions.to_a
      assert sessions.any?
    end
  end

  # ========== Security Considerations Tests ==========

  test "세션 생성을 정상적으로 처리해야 한다" do
    # Multiple sessions can be created without issues since IDs are auto-generated
    session1 = Session.create!(user: @user, ip_address: "127.0.0.1", user_agent: "Test1")
    session2 = Session.create!(user: users(:jane), ip_address: "127.0.0.1", user_agent: "Test2")

    assert session1.valid?
    assert session2.valid?
    assert_not_equal session1.id, session2.id
  end

  test "매우 긴 사용자 에이전트 문자열을 처리해야 한다" do
    # Test with very long user agent (within reasonable limits)
    long_agent = "Mozilla/5.0 " + ("a" * 500)

    session = Session.new(
      user: @user,
      ip_address: "127.0.0.1",
      user_agent: long_agent
    )

    # Should either be valid or have appropriate length validation
    if session.valid?
      session.save!
      assert_equal long_agent, session.user_agent
    else
      # Should have length validation error if there is one
      assert session.errors[:user_agent].any?
    end
  end

  # ========== Edge Cases and Error Handling ==========

  test "동시 세션 생성을 처리해야 한다" do
    user = @user

    # Simulate concurrent session creation
    threads = 3.times.map do |i|
      Thread.new do
        Session.create!(
          user: user,
          ip_address: "127.0.0.#{i}",
          user_agent: "Concurrent #{i}"
        )
      end
    end

    sessions = threads.map(&:value)

    # All sessions should be created successfully
    assert_equal 3, sessions.length
    sessions.each do |session|
      assert session.persisted?
      assert_equal user, session.user
    end
  end

  test "데이터베이스 제약 조건을 올바르게 처리해야 한다" do
    # Test that database-level constraints are properly handled

    # Try to create session with non-existent user_id
    session = Session.new(ip_address: "127.0.0.1", user_agent: "Test")
    session.user_id = 99999 # Non-existent user ID

    assert_raises ActiveRecord::RecordInvalid do
      session.save!
    end
  end

  # ========== Current Integration Tests ==========

  test "Current.session과 함께 작동해야 한다" do
    # Test integration with Current attributes system
    session = @session

    # This tests the integration pattern, even if Current is simple
    Current.session = session

    assert_equal session, Current.session
    if Current.respond_to?(:user)
      assert_equal session.user, Current.user
    end
  ensure
    Current.reset # Clean up
  end

  # ========== Fixture Validation Tests ==========

  test "모든 fixture 세션은 유효해야 한다" do
    Session.all.each do |session|
      assert session.valid?, "Session #{session.id} should be valid: #{session.errors.full_messages.join(', ')}"
    end
  end

  test "fixture 세션은 고유한 id를 가져야 한다" do
    session_ids = Session.pluck(:id)
    assert_equal session_ids.uniq.length, session_ids.length, "All session IDs should be unique"
  end

  test "fixture 세션은 유효한 사용자에 속해야 한다" do
    Session.all.each do |session|
      assert_not_nil session.user, "Session #{session.id} should have a user"
      assert session.user.valid?, "Session #{session.id} should belong to a valid user"
    end
  end

  # ========== Integration with Korean Timezone ==========

  test "한국 시간대와 올바르게 작동해야 한다" do
    Time.zone = "Asia/Seoul"

    # Create session in Korean timezone
    korean_time = Time.zone.parse("2024-07-01 09:00:00")

    travel_to korean_time do
      session = Session.create!(
        user: users(:korean_user),
        ip_address: "127.0.0.1",
        user_agent: "Korean Test"
      )

      assert_equal "Asia/Seoul", Time.zone.name
      assert_equal korean_time.to_i, session.created_at.to_i
      assert_kind_of ActiveSupport::TimeWithZone, session.created_at
    end
  end

  # ========== Cleanup and Maintenance Tests ==========

  test "세션 정리 작업을 지원해야 한다" do
    # Test that sessions can be cleaned up efficiently
    old_sessions = []

    # Create some old sessions
    travel_to 1.month.ago do
      3.times do |i|
        old_sessions << Session.create!(
          user: @user,
          ip_address: "127.0.0.#{i}",
          user_agent: "Old #{i}"
        )
      end
    end

    # Should be able to delete old sessions efficiently
    assert_difference "Session.count", -3 do
      cutoff_time = 2.weeks.ago
      Session.where("created_at < ?", cutoff_time).delete_all
    end

    # Verify they're gone
    old_sessions.each do |session|
      assert_not Session.exists?(session.id)
    end
  end

  private

  # Helper method for testing query count
  def assert_queries(expected_count)
    queries = []
    ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
      queries << payload[:sql] unless payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/
    end

    yield

    assert_equal expected_count, queries.size, "Expected #{expected_count} queries, got #{queries.size}"
  ensure
    ActiveSupport::Notifications.unsubscribe("sql.active_record")
  end
end
