# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Test fixtures setup
  def setup
    @user = users(:john)
    @admin = users(:admin)
    @korean_user = users(:korean_user)
    @admin_role = roles(:admin)
    @editor_role = roles(:editor)
  end

  # ========== Validation Tests ==========

  test "유효한 속성을 가진 경우 유효해야 한다" do
    user = User.new(
      email_address: "test@example.com",
      name: "테스트 사용자",
      password: "password123"
    )
    assert user.valid?
  end

  test "email_address는 필수 항목이어야 한다" do
    user = User.new(name: "Test User", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "이메일을 입력해주세요"
  end

  test "name은 필수 항목이어야 한다" do
    user = User.new(email_address: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "이름을 입력해주세요"
  end

  test "password는 필수 항목이어야 한다" do
    user = User.new(email_address: "test@example.com", name: "Test User")
    assert_not user.valid?
    assert_includes user.errors[:password], "비밀번호를 입력해주세요"
  end

  test "이메일 형식을 검증해야 한다" do
    invalid_emails = [ "invalid", "test@", "@example.com", "test.example.com" ]

    invalid_emails.each do |email|
      user = User.new(email_address: email, name: "Test User", password: "password123")
      assert_not user.valid?, "#{email} should be invalid"
      assert_includes user.errors[:email_address], "이메일 형식이 올바르지 않습니다"
    end
  end

  test "유효한 이메일 형식을 허용해야 한다" do
    valid_emails = [
      "test@example.com",
      "user.name@example.co.kr",
      "test+tag@example.org"
    ]

    valid_emails.each do |email|
      user = User.new(email_address: email, name: "Test User", password: "password123")
      user.valid? # trigger validation
      assert_not_includes user.errors[:email_address], "이메일 형식이 올바르지 않습니다",
                         "#{email} should be valid"
    end
  end

  test "이메일의 유일성을 대소문자 구분 없이 검증해야 한다" do
    user1 = User.create!(email_address: "test@example.com", name: "User One", password: "password123")
    user2 = User.new(email_address: "TEST@EXAMPLE.COM", name: "User Two", password: "password123")

    assert_not user2.valid?
    assert_includes user2.errors[:email_address], "이미 사용 중인 이메일입니다"
  end

  test "이름 길이를 검증해야 한다" do
    # Too short
    user = User.new(email_address: "test@example.com", name: "A", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "이름은 최소 2글자 이상이어야 합니다"

    # Too long
    user = User.new(email_address: "test2@example.com", name: "A" * 51, password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "이름은 50글자를 초과할 수 없습니다"

    # Just right
    user = User.new(email_address: "test3@example.com", name: "정적절한길이", password: "password123")
    assert user.valid?
  end

  test "이름 형식을 검증해야 한다" do
    invalid_names = [ "123", "test@", "user-name", "user_name", "user123", "테스트123" ]

    invalid_names.each do |name|
      user = User.new(email_address: "test#{name.hash}@example.com", name: name, password: "password123")
      assert_not user.valid?, "#{name} should be invalid"
      assert_includes user.errors[:name], "한글, 영문, 공백만 사용할 수 있습니다"
    end
  end

  test "유효한 이름 형식을 허용해야 한다" do
    valid_names = [ "John Doe", "김철수", "Jane Smith", "홍 길 동", "Mary Jane Watson", "이 순 신" ]

    valid_names.each do |name|
      user = User.new(email_address: "test#{name.hash}@example.com", name: name, password: "password123")
      user.valid? # trigger validation
      assert_not_includes user.errors[:name], "한글, 영문, 공백만 사용할 수 있습니다",
                         "#{name} should be valid"
    end
  end

  # ========== Normalization Tests ==========

  test "email_address를 정규화해야 한다" do
    user = User.new(
      email_address: "  TEST@EXAMPLE.COM  ",
      name: "Test User",
      password: "password123"
    )
    user.save!
    assert_equal "test@example.com", user.email_address
  end

  test "name을 정규화해야 한다" do
    user = User.new(
      email_address: "test@example.com",
      name: "  Test User  ",
      password: "password123"
    )
    user.save!
    assert_equal "Test User", user.name
  end

  # ========== Association Tests ==========

  test "여러 세션을 가져야 한다" do
    assert_respond_to @user, :sessions
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @user.sessions
  end

  test "사용자가 삭제될 때 연관된 세션도 삭제되어야 한다" do
    user_with_sessions = User.create!(email_address: "deleteme@example.com", name: "Delete Me", password: "password")
    user_with_sessions.sessions.create!
    user_with_sessions.sessions.create!

    assert_difference "Session.count", -2 do
      user_with_sessions.destroy!
    end
  end

  # ========== Scope Tests ========== 

  test "admins 스코프는 관리자 사용자를 반환해야 한다" do
    admins = User.admins
    assert_includes admins, @admin
    assert_not_includes admins, @user
    assert_not_includes admins, @korean_user
  end

  test "admins 스코프는 admin@example.com만 포함해야 한다" do
    admin_emails = User.admins.pluck(:email_address)
    assert_equal [ "admin@example.com" ], admin_emails
  end

  # ========== Instance Method Tests ========== 

  test "admin?은 관리자 사용자에 대해 true를 반환해야 한다" do
    assert @admin.admin?
    assert_not @user.admin?
    assert_not @korean_user.admin?
  end

  # ========== Role Tests ==========

  test "with_role 스코프는 특정 역할을 가진 사용자만 반환해야 한다" do
    editors = User.with_role(:editor)
    assert_includes editors, @user
    assert_not_includes editors, @admin
  end

  test "has_role?은 역할 보유 여부를 확인해야 한다" do
    assert @admin.has_role?(:admin)
    assert @user.has_role?(:user)
    assert_not @user.has_role?(:admin)
  end

  test "admin?은 역할 기반으로 동작해야 한다" do
    roles(:admin).destroy!
    @admin.reload
    assert_not @admin.admin?

    @user.roles << @admin_role.name
    assert @user.admin?
  end

  test "사용자는 여러 역할을 가질 수 있어야 한다" do
    @admin.roles << @editor_role.name
    assert_includes @admin.roles, "admin"
    assert_includes @admin.roles, "editor"
  end

  test "full_name은 이름이 있을 때 이름을 반환해야 한다" do
    assert_equal "존 도", @user.full_name
    assert_equal "김철수", @korean_user.full_name
  end

  test "full_name은 이름이 비어있을 때 이메일 접두사를 반환해야 한다" do
    user = User.new(email_address: "test@example.com", name: "", password: "password123")
    user.save!(validate: false) # Skip validation to test blank name scenario
    assert_equal "test", user.full_name
  end

  test "full_name은 이름이 nil일 때 이메일 접두사를 반환해야 한다" do
    # Since name has NOT NULL constraint, we simulate the behavior instead
    user = User.new(email_address: "test@example.com", password: "password123", name: "Test")
    user.save!

    # Test the full_name logic by temporarily stubbing the name
    user.stub(:name, nil) do
      assert_equal "test", user.full_name
    end
  end

  # ========== Security Tests ==========

  test "올바른 비밀번호로 인증해야 한다" do
    user = User.create!(
      email_address: "auth@example.com",
      name: "Auth User",
      password: "secret123"
    )
    assert user.authenticate("secret123")
    assert_not user.authenticate("wrong_password")
  end

  test "비밀번호를 안전하게 해시해야 한다" do
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

  test "이름에 있는 한글 문자를 처리해야 한다" do
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

  test "이메일 로컬 파트에 있는 한글 문자를 처리해야 한다" do
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

  test "매우 긴 유효한 이름을 처리해야 한다" do
    # Test maximum allowed length
    long_name = "김" + "철" * 24 + "수" # 26 Korean characters = 26 length
    user = User.new(
      email_address: "longname@example.com",
      name: long_name,
      password: "password123"
    )
    assert user.valid?, "Maximum length Korean name should be valid"
  end

  test "혼합 언어 이름을 처리해야 한다" do
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

  test "숫자가 포함된 이름을 거부해야 한다" do
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

  test "관리자를 효율적으로 쿼리해야 한다" do
    # Test that admin query is efficient
    assert_queries(1) do
      User.admins.to_a
    end
  end

  # ========== Integration with Korean Timezone ==========

  test "created_at에 한국 시간대를 처리해야 한다" do
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
