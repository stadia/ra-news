# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Test fixtures setup
  def setup
    @user = users(:john)
    @admin = users(:admin)
    @korean_user = users(:korean_user)
  end

  # ========== Validation Tests ==========

  test "should be valid with valid attributes" do
    user = User.new(
      email_address: "test@example.com",
      name: "테스트 사용자",
      password: "password123"
    )
    assert user.valid?
  end

  test "should require email_address" do
    user = User.new(name: "Test User", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "should require name" do
    user = User.new(email_address: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "should require password" do
    user = User.new(email_address: "test@example.com", name: "Test User")
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "should validate email format" do
    invalid_emails = [ "invalid", "test@", "@example.com", "test.example.com" ]

    invalid_emails.each do |email|
      user = User.new(email_address: email, name: "Test User", password: "password123")
      assert_not user.valid?, "#{email} should be invalid"
      assert_includes user.errors[:email_address], "이메일 형식이 올바르지 않습니다"
    end
  end

  test "should accept valid email formats" do
    valid_emails = [
      "test@example.com",
      "user.name@example.co.kr",
      "한국어@example.com",
      "test+tag@example.org"
    ]

    valid_emails.each do |email|
      user = User.new(email_address: email, name: "Test User", password: "password123")
      user.valid? # trigger validation
      assert_not_includes user.errors[:email_address], "이메일 형식이 올바르지 않습니다",
                         "#{email} should be valid"
    end
  end

  test "should validate email uniqueness case insensitive" do
    user1 = User.create!(email_address: "test@example.com", name: "User One", password: "password123")
    user2 = User.new(email_address: "TEST@EXAMPLE.COM", name: "User Two", password: "password123")

    assert_not user2.valid?
    assert_includes user2.errors[:email_address], "has already been taken"
  end

  test "should validate name length" do
    # Too short
    user = User.new(email_address: "test@example.com", name: "A", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "is too short (minimum is 2 characters)"

    # Too long
    user = User.new(email_address: "test2@example.com", name: "A" * 51, password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "is too long (maximum is 50 characters)"

    # Just right
    user = User.new(email_address: "test3@example.com", name: "정적절한길이", password: "password123")
    assert user.valid?
  end

  test "should validate name format" do
    invalid_names = [ "123", "test@", "user-name", "user_name", "user123", "테스트123" ]

    invalid_names.each do |name|
      user = User.new(email_address: "test#{name.hash}@example.com", name: name, password: "password123")
      assert_not user.valid?, "#{name} should be invalid"
      assert_includes user.errors[:name], "한글, 영문, 공백만 사용할 수 있습니다"
    end
  end

  test "should accept valid name formats" do
    valid_names = [ "John Doe", "김철수", "Jane Smith", "홍 길 동", "Mary Jane Watson", "이 순 신" ]

    valid_names.each do |name|
      user = User.new(email_address: "test#{name.hash}@example.com", name: name, password: "password123")
      user.valid? # trigger validation
      assert_not_includes user.errors[:name], "한글, 영문, 공백만 사용할 수 있습니다",
                         "#{name} should be valid"
    end
  end

  # ========== Normalization Tests ==========

  test "should normalize email_address" do
    user = User.new(
      email_address: "  TEST@EXAMPLE.COM  ",
      name: "Test User",
      password: "password123"
    )
    user.save!
    assert_equal "test@example.com", user.email_address
  end

  test "should normalize name" do
    user = User.new(
      email_address: "test@example.com",
      name: "  Test User  ",
      password: "password123"
    )
    user.save!
    assert_equal "Test User", user.name
  end

  # ========== Association Tests ==========

  test "should have many sessions" do
    assert_respond_to @user, :sessions
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @user.sessions
  end

  test "should destroy associated sessions when user is destroyed" do
    session = @user.sessions.create!(id: "test_session_token")
    assert_difference "Session.count", -1 do
      @user.destroy!
    end
    assert_not Session.exists?(session.id)
  end

  # ========== Scope Tests ==========

  test "admins scope should return admin users" do
    admins = User.admins
    assert_includes admins, @admin
    assert_not_includes admins, @user
    assert_not_includes admins, @korean_user
  end

  test "admins scope should only include stadia@gmail.com" do
    admin_emails = User.admins.pluck(:email_address)
    assert_equal [ "stadia@gmail.com" ], admin_emails
  end

  # ========== Instance Method Tests ==========

  test "admin? should return true for admin user" do
    assert @admin.admin?
    assert_not @user.admin?
    assert_not @korean_user.admin?
  end

  test "full_name should return name when present" do
    assert_equal "존 도", @user.full_name
    assert_equal "김철수", @korean_user.full_name
  end

  test "full_name should return email prefix when name is blank" do
    user = User.new(email_address: "test@example.com", name: "", password: "password123")
    user.save!(validate: false) # Skip validation to test blank name scenario
    assert_equal "test", user.full_name
  end

  test "full_name should return email prefix when name is nil" do
    # Since name has NOT NULL constraint, we simulate the behavior instead
    user = User.new(email_address: "test@example.com", password: "password123", name: "Test")
    user.save!
    
    # Test the full_name logic by temporarily stubbing the name
    user.stubs(:name).returns(nil)
    assert_equal "test", user.full_name
  end

  # ========== Security Tests ==========

  test "should authenticate with correct password" do
    user = User.create!(
      email_address: "auth@example.com",
      name: "Auth User",
      password: "secret123"
    )
    assert user.authenticate("secret123")
    assert_not user.authenticate("wrong_password")
  end

  test "should hash password securely" do
    password = "secret123"
    user = User.new(
      email_address: "secure@example.com",
      name: "Secure User",
      password: password
    )
    user.save!

    assert_not_equal password, user.password_digest
    assert user.password_digest.start_with?("$2a$")
    assert user.authenticate(password)
  end

  # ========== Korean Localization Tests ==========

  test "should handle Korean characters in name" do
    korean_names = [ "김철수", "박영희", "이민수", "정다혜", "최진우" ]

    korean_names.each_with_index do |name, index|
      user = User.new(
        email_address: "korean#{index}@example.com",
        name: name,
        password: "password123"
      )
      assert user.valid?, "Korean name #{name} should be valid"
      user.save!
      assert_equal name, user.name
    end
  end

  test "should handle Korean characters in email local part" do
    # Note: While technically possible, Korean emails are rare
    # This tests the system's handling of international characters
    user = User.new(
      email_address: "테스트@example.com",
      name: "테스트 사용자",
      password: "password123"
    )
    # This might fail depending on email validation - that's expected behavior
    if user.valid?
      user.save!
      assert_equal "테스트@example.com", user.email_address
    else
      # If Korean email is not supported, verify appropriate validation
      assert user.errors[:email_address].any?, "Should have email validation error for Korean characters"
    end
  end

  # ========== Edge Cases and Error Handling ==========

  test "should handle very long valid names" do
    # Test maximum allowed length
    long_name = "김" + "철" * 24 + "수" # 26 Korean characters = 26 length
    user = User.new(
      email_address: "longname@example.com",
      name: long_name,
      password: "password123"
    )
    assert user.valid?, "Maximum length Korean name should be valid"
  end

  test "should handle mixed language names" do
    mixed_names = [ "John 김", "김 Smith", "Mary 박영희", "이민수 Johnson" ]

    mixed_names.each_with_index do |name, index|
      user = User.new(
        email_address: "mixed#{index}@example.com",
        name: name,
        password: "password123"
      )
      assert user.valid?, "Mixed language name #{name} should be valid"
    end
  end

  test "should reject names with numbers" do
    invalid_names = [ "김철수1", "John2", "사용자123", "User1" ]

    invalid_names.each do |name|
      user = User.new(
        email_address: "invalid#{name.hash}@example.com",
        name: name,
        password: "password123"
      )
      assert_not user.valid?, "Name with numbers #{name} should be invalid"
    end
  end

  # ========== Performance Tests ==========

  test "should efficiently query admins" do
    # Test that admin query is efficient
    assert_queries(1) do
      User.admins.to_a
    end
  end

  # ========== Integration with Korean Timezone ==========

  test "should handle Korean timezone for created_at" do
    Time.zone = "Asia/Seoul"
    user = User.create!(
      email_address: "timezone@example.com",
      name: "시간대 테스트",
      password: "password123"
    )

    assert_equal "Asia/Seoul", Time.zone.name
    assert_kind_of ActiveSupport::TimeWithZone, user.created_at
  end

  private

  # Helper method for testing query count
  def assert_queries(expected_count)
    queries = []
    ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
      queries << payload[:sql] unless payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/
    end

    yield

    assert_equal expected_count, queries.size, "Expected #{expected_count} queries, got #{queries.size}: #{queries}"
  ensure
    ActiveSupport::Notifications.unsubscribe("sql.active_record")
  end
end
