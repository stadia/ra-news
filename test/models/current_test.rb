# frozen_string_literal: true

require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  # Test fixtures setup
  def setup
    @session = sessions(:john_session)
    @admin_session = sessions(:admin_session)
    @korean_session = sessions(:korean_session)
    @user = users(:john)
    @admin = users(:admin)
    @korean_user = users(:korean_user)
  end

  def teardown
    # Clean up Current state after each test
    Current.reset
  end

  # ========== Inheritance Tests ==========

  test "ActiveSupport::CurrentAttributes를 상속해야 한다" do
    assert Current.ancestors.include?(ActiveSupport::CurrentAttributes)
  end

  test "ActiveSupport::CurrentAttributes 기능이 있어야 한다" do
    # Test that basic CurrentAttributes functionality is available
    assert_respond_to Current, :reset
    assert_respond_to Current, :set
    assert_respond_to Current, :session
    assert_respond_to Current, :session=
    assert_respond_to Current, :user
  end

  # ========== Session Attribute Tests ==========

  test "세션을 저장하고 검색할 수 있어야 한다" do
    Current.session = @session
    assert_equal @session, Current.session
  end

  test "nil 세션을 처리해야 한다" do
    Current.session = nil
    assert_nil Current.session
  end

  test "세션을 재설정해야 한다" do
    Current.session = @session
    assert_equal @session, Current.session

    Current.reset
    assert_nil Current.session
  end

  test "세션 변경을 처리해야 한다" do
    # Set initial session
    Current.session = @session
    assert_equal @session, Current.session

    # Change to different session
    Current.session = @admin_session
    assert_equal @admin_session, Current.session
    assert_not_equal @session, Current.session
  end

  # ========== User Delegation Tests ==========

  test "세션이 있을 때 user를 세션에 위임해야 한다" do
    Current.session = @session
    assert_equal @user, Current.user
    assert_equal @session.user, Current.user
  end

  test "세션이 nil일 때 nil user를 반환해야 한다" do
    Current.session = nil
    assert_nil Current.user
  end

  test "세션 사용자가 nil일 때 nil user를 반환해야 한다" do
    # Create a session without a user (edge case)
    session_without_user = Session.new(id: "orphan_session")
    session_without_user.user = nil

    Current.session = session_without_user
    assert_nil Current.user
  end

  test "세션 변경을 통해 사용자 변경을 처리해야 한다" do
    # Start with first user
    Current.session = @session
    assert_equal @user, Current.user

    # Change to admin user
    Current.session = @admin_session
    assert_equal @admin, Current.user
    assert_not_equal @user, Current.user

    # Change to Korean user
    Current.session = @korean_session
    assert_equal @korean_user, Current.user
    assert_not_equal @admin, Current.user
  end

  # ========== Allow_nil Delegation Tests ==========

  test "allow_nil 옵션으로 위임을 처리해야 한다" do
    # When session is nil, user should also be nil without raising error
    Current.session = nil

    assert_nothing_raised do
      user = Current.user
      assert_nil user
    end
  end

  # ========== Thread Safety Tests ==========

  test "스레드 간에 Current 상태를 격리해야 한다" do
    # Set current values in main thread
    Current.session = @session
    Current.set(session: @session) do
      assert_equal @session, Current.session
      assert_equal @user, Current.user

      # Create another thread with different current values
      thread_result = nil
      thread = Thread.new do
        Current.session = @admin_session
        thread_result = {
          session: Current.session,
          user: Current.user
        }
      end

      thread.join

      # Main thread should retain its values
      assert_equal @session, Current.session
      assert_equal @user, Current.user

      # Thread should have had different values
      assert_equal @admin_session, thread_result[:session]
      assert_equal @admin, thread_result[:user]
    end
  end

  test "동시 접근을 안전하게 처리해야 한다" do
    results = {}

    # Run multiple threads with different sessions
    threads = [
      [ @session, @user ],
      [ @admin_session, @admin ],
      [ @korean_session, @korean_user ]
    ].map.with_index do |(session, expected_user), index|
      Thread.new do
        Current.session = session

        # Small delay to increase chance of thread interaction
        sleep 0.01

        results[index] = {
          session: Current.session,
          user: Current.user,
          expected_user: expected_user
        }
      end
    end

    threads.each(&:join)

    # Each thread should have maintained its own state
    results.each do |index, result|
      assert_equal result[:expected_user], result[:user],
                  "Thread #{index} should have correct user"
    end
  end

  # ========== Set Block Context Tests ==========

  test "set 블록 컨텍스트와 함께 작동해야 한다" do
    # Ensure initial state is clean
    Current.reset
    assert_nil Current.session

    Current.set(session: @session) do
      assert_equal @session, Current.session
      assert_equal @user, Current.user
    end

    # Should be reset after block
    assert_nil Current.session
    assert_nil Current.user
  end

  test "중첩된 set 블록을 처리해야 한다" do
    Current.set(session: @session) do
      assert_equal @session, Current.session
      assert_equal @user, Current.user

      Current.set(session: @admin_session) do
        assert_equal @admin_session, Current.session
        assert_equal @admin, Current.user
      end

      # Should restore outer context
      assert_equal @session, Current.session
      assert_equal @user, Current.user
    end
  end

  test "블록에서 예외가 발생하더라도 상태를 복원해야 한다" do
    Current.session = @session
    initial_session = Current.session

    begin
      Current.set(session: @admin_session) do
        assert_equal @admin_session, Current.session
        raise StandardError, "Test exception"
      end
    rescue StandardError
      # Exception should be re-raised, but state should be restored
    end

    assert_equal initial_session, Current.session
  end

  # ========== Integration Tests ==========

  test "인증 시스템과 통합되어야 한다" do
    # Test typical authentication flow
    Current.reset

    # No user initially
    assert_nil Current.user

    # Set session (simulate login)
    Current.session = @session
    assert_equal @user, Current.user

    # Check user properties through Current
    assert_equal @user.name, Current.user.name
    assert_equal @user.email_address, Current.user.email_address
    assert_equal @user.admin?, Current.user.admin?
  end

  test "관리자 사용자와 함께 작동해야 한다" do
    Current.session = @admin_session

    assert_equal @admin, Current.user
    assert Current.user.admin?
    assert_equal "admin@example.com", Current.user.email_address
  end

  test "한국인 사용자와 함께 작동해야 한다" do
    Current.session = @korean_session

    assert_equal @korean_user, Current.user
    assert_equal "김철수", Current.user.name
    assert_equal "korean@example.com", Current.user.email_address
    assert_not Current.user.admin?
  end

  # ========== Controller Integration Simulation Tests ==========

  test "컨트롤러 요청 생명주기를 시뮬레이션해야 한다" do
    # Simulate request start - no current user
    Current.reset
    assert_nil Current.user

    # Simulate authentication middleware setting session
    Current.session = @session
    assert_equal @user, Current.user

    # Simulate controller actions having access to current user
    current_user_name = Current.user.name
    assert_equal @user.name, current_user_name

    # Simulate request end - cleanup
    Current.reset
    assert_nil Current.user
  end

  test "여러 요청 시뮬레이션을 처리해야 한다" do
    # Simulate multiple requests with different users
    requests = [
      [ @session, @user ],
      [ @admin_session, @admin ],
      [ @korean_session, @korean_user ],
      [ nil, nil ] # Unauthenticated request
    ]

    requests.each do |session, expected_user|
      # Simulate request start
      Current.reset
      Current.session = session

      # Verify correct user context
      if expected_user.nil?
        assert_nil Current.user
      else
        assert_equal expected_user, Current.user
      end

      # Simulate request end
      Current.reset
      assert_nil Current.user
    end
  end

  # ========== Error Handling Tests ==========

  test "사용자가 없는 세션을 정상적으로 처리해야 한다" do
    # Create a session that exists but has no associated user
    session = Session.new(id: "test_session_no_user")
    # Deliberately don't set user

    Current.session = session

    assert_nothing_raised do
      user = Current.user
      assert_nil user
    end
  end

  # ========== State Management Tests ==========

  test "재설정 간에 독립적인 상태를 유지해야 한다" do
    # Set initial state
    Current.session = @session
    initial_user = Current.user
    assert_equal @user, initial_user

    # Reset
    Current.reset
    assert_nil Current.session
    assert_nil Current.user

    # Set different state
    Current.session = @admin_session
    new_user = Current.user
    assert_equal @admin, new_user
    assert_not_equal initial_user, new_user
  end

  test "빠른 상태 변경을 처리해야 한다" do
    sessions_and_users = [
      [ @session, @user ],
      [ @admin_session, @admin ],
      [ @korean_session, @korean_user ],
      [ @session, @user ]
    ]

    sessions_and_users.each do |session, expected_user|
      Current.session = session
      assert_equal expected_user, Current.user
      assert_equal session, Current.session
    end
  end

  # ========== Performance Tests ==========

  test "현재 사용자를 효율적으로 접근해야 한다" do
    Current.session = @session

    # Preload the user to ensure no queries are made inside the block
    Current.user

    # Multiple accesses should not cause additional database queries
    # (assuming session and user are already loaded)
    assert_queries(0) do
      10.times do
        user = Current.user
        assert_equal @user, user
      end
    end
  end

  # ========== Memory Management Tests ==========

  test "Current 속성을 통해 메모리가 누수되지 않아야 한다" do
    # Test that objects don't accumulate in Current
    initial_session = @session

    # Set and reset many times
    100.times do |i|
      Current.session = i.even? ? @session : @admin_session
      Current.reset
    end

    # Should be clean
    assert_nil Current.session
    assert_nil Current.user

    # Original objects should still be valid
    assert_equal @user, initial_session.user
  end

  # ========== Integration with Korean Timezone ==========

  test "한국 시간대와 올바르게 작동해야 한다" do
    Time.zone = "Asia/Seoul"

    Current.session = @korean_session
    user = Current.user

    assert_equal @korean_user, user
    assert_equal "Asia/Seoul", Time.zone.name

    # Should have access to user's Korean attributes
    assert_equal "김철수", user.name
  end

  # ========== Debugging and Inspection Tests ==========

  test "유용한 검사를 제공해야 한다" do
    Current.reset
    Current.session = @session

    # Should be able to inspect Current state
    assert_respond_to Current, :inspect

    # Attributes should be accessible for debugging
    assert_not_nil Current.session
    assert_not_nil Current.user
  end

  test "nil 값으로 검사를 처리해야 한다" do
    Current.reset

    # Should handle inspection even when values are nil
    assert_nothing_raised do
      Current.inspect
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
