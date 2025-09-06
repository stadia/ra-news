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

  test "should inherit from ActiveSupport::CurrentAttributes" do
    assert Current.ancestors.include?(ActiveSupport::CurrentAttributes)
  end

  test "should have ActiveSupport::CurrentAttributes functionality" do
    # Test that basic CurrentAttributes functionality is available
    assert_respond_to Current, :reset
    assert_respond_to Current, :set
    assert_respond_to Current, :session
    assert_respond_to Current, :session=
    assert_respond_to Current, :user
  end

  # ========== Session Attribute Tests ==========

  test "should store and retrieve session" do
    Current.session = @session
    assert_equal @session, Current.session
  end

  test "should handle nil session" do
    Current.session = nil
    assert_nil Current.session
  end

  test "should reset session" do
    Current.session = @session
    assert_equal @session, Current.session

    Current.reset
    assert_nil Current.session
  end

  test "should handle session changes" do
    # Set initial session
    Current.session = @session
    assert_equal @session, Current.session

    # Change to different session
    Current.session = @admin_session
    assert_equal @admin_session, Current.session
    assert_not_equal @session, Current.session
  end

  # ========== User Delegation Tests ==========

  test "should delegate user to session when session present" do
    Current.session = @session
    assert_equal @user, Current.user
    assert_equal @session.user, Current.user
  end

  test "should return nil user when session is nil" do
    Current.session = nil
    assert_nil Current.user
  end

  test "should return nil user when session user is nil" do
    # Create a session without a user (edge case)
    session_without_user = Session.new(id: "orphan_session")
    session_without_user.user = nil

    Current.session = session_without_user
    assert_nil Current.user
  end

  test "should handle user changes through session changes" do
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

  test "should handle delegation with allow_nil option" do
    # When session is nil, user should also be nil without raising error
    Current.session = nil

    assert_nothing_raised do
      user = Current.user
      assert_nil user
    end
  end

  test "should not raise error when session lacks user method" do
    # Create an object that doesn't respond to :user
    fake_session = Object.new
    Current.session = fake_session

    # Should not raise NoMethodError due to allow_nil: true
    assert_nothing_raised do
      user = Current.user
      assert_nil user
    end
  end

  # ========== Thread Safety Tests ==========

  test "should isolate Current state between threads" do
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

  test "should handle concurrent access safely" do
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

  test "should work with set block context" do
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

  test "should handle nested set blocks" do
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

  test "should restore state even if exception occurs in block" do
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

  test "should integrate with authentication system" do
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

  test "should work with admin users" do
    Current.session = @admin_session

    assert_equal @admin, Current.user
    assert Current.user.admin?
    assert_equal "stadia@gmail.com", Current.user.email_address
  end

  test "should work with Korean users" do
    Current.session = @korean_session

    assert_equal @korean_user, Current.user
    assert_equal "김철수", Current.user.name
    assert_equal "korean@example.com", Current.user.email_address
    assert_not Current.user.admin?
  end

  # ========== Controller Integration Simulation Tests ==========

  test "should simulate controller request lifecycle" do
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

  test "should handle multiple request simulation" do
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

  test "should handle invalid session objects gracefully" do
    # Test with various invalid session-like objects
    invalid_sessions = [
      "not_a_session",
      123,
      {},
      [],
      OpenStruct.new(user: @user), # Has user but not a real Session
      Session.new # Unsaved session
    ]

    invalid_sessions.each do |invalid_session|
      Current.reset
      Current.session = invalid_session

      # Should not raise errors due to allow_nil delegation
      assert_nothing_raised do
        user = Current.user
        # User might be nil or the actual user, depending on the object
      end
    end
  end

  test "should handle session with missing user gracefully" do
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

  test "should maintain independent state across resets" do
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

  test "should handle rapid state changes" do
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

  test "should access current user efficiently" do
    Current.session = @session

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

  test "should not leak memory through Current attributes" do
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

  test "should work correctly with Korean timezone" do
    Time.zone = "Asia/Seoul"

    Current.session = @korean_session
    user = Current.user

    assert_equal @korean_user, user
    assert_equal "Asia/Seoul", Time.zone.name

    # Should have access to user's Korean attributes
    assert_equal "김철수", user.name
  end

  # ========== Debugging and Inspection Tests ==========

  test "should provide useful inspection" do
    Current.reset
    Current.session = @session

    # Should be able to inspect Current state
    assert_respond_to Current, :inspect

    # Attributes should be accessible for debugging
    assert_not_nil Current.session
    assert_not_nil Current.user
  end

  test "should handle inspect with nil values" do
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
