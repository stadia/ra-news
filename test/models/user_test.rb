# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:john)
    @admin = users(:admin)
    @korean_user = users(:korean_user)
    @admin_role = roles(:admin)
    @editor_role = roles(:editor)
  end

  test "유효한 속성을 가진 경우 유효해야 한다" do
    assert_predicate build_user(email: "test@example.com", username: "test_user", name: "테스트 사용자"), :valid?
  end

  test "email는 필수 항목이어야 한다" do
    user = build_user(email: nil)

    assert_not user.valid?
    assert_includes user.errors[:email], "을(를) 입력해주세요"
  end

  test "username은 필수 항목이어야 한다" do
    user = build_user(username: nil)

    assert_not user.valid?
    assert_includes user.errors[:username], "을(를) 입력해주세요"
  end

  test "name은 비어 있어도 된다" do
    assert_predicate build_user(name: nil), :valid?
    assert_predicate build_user(name: ""), :valid?
  end

  test "password는 필수 항목이어야 한다" do
    user = build_user(password: nil)

    assert_not user.valid?
    assert_includes user.errors[:password], "을(를) 입력해주세요"
  end

  test "이메일 형식을 검증해야 한다" do
    [ "invalid", "test@", "@example.com", "test.example.com" ].each do |email|
      user = build_user(email:, username: "invalid_#{email.hash.abs}")

      assert_not user.valid?, "#{email} should be invalid"
      assert_includes user.errors[:email], "형식이 올바르지 않습니다"
    end
  end

  test "유효한 이메일 형식을 허용해야 한다" do
    [ "test@example.com", "user.name@example.co.kr", "test+tag@example.org", "테스트@example.com" ].each do |email|
      user = build_user(email:, username: "valid_#{email.hash.abs}")
      user.valid?

      assert_empty user.errors[:email], "#{email} should be valid"
    end
  end

  test "이메일의 유일성을 대소문자 구분 없이 검증해야 한다" do
    User.create!(email: "test@example.com", username: "unique_email_source", name: "User One", password: "password123", confirmed_at: Time.current)
    user = build_user(email: "TEST@EXAMPLE.COM", username: "user_two")

    assert_not user.valid?
    assert_includes user.errors[:email], "은(는) 이미 사용 중입니다"
  end

  test "username의 유일성을 대소문자 구분 없이 검증해야 한다" do
    User.create!(email: "case1@example.com", username: "case_user", name: "User One", password: "password123", confirmed_at: Time.current)
    user = build_user(email: "case2@example.com", username: "CASE_USER")

    assert_not user.valid?
    assert_includes user.errors[:username], "은(는) 이미 사용 중입니다"
  end

  test "이름 길이를 검증해야 한다" do
    too_short = build_user(name: "A", username: "short_name", email: "short@example.com")
    too_long = build_user(name: "A" * 51, username: "long_name", email: "long@example.com")
    valid = build_user(name: "정적절한길이", username: "valid_name", email: "valid@example.com")

    assert_not too_short.valid?
    assert_includes too_short.errors[:name], "은(는) 2자 이상이어야 합니다"

    assert_not too_long.valid?
    assert_includes too_long.errors[:name], "은(는) 50자 이하여야 합니다"

    assert_predicate valid, :valid?
  end

  test "username 형식을 검증해야 한다" do
    invalid_usernames = [ "한글", "test@", "user-name", "user name", "a", "user!" ]

    invalid_usernames.each do |username|
      user = build_user(username:, email: "test#{username.hash.abs}@example.com")

      assert_not user.valid?, "#{username} should be invalid"
      assert user.errors[:username].any? { |message| [ "영문, 숫자, 밑줄, 점만 사용할 수 있습니다", "은(는) 2자 이상이어야 합니다" ].include?(message) }
    end
  end

  test "유효한 username 형식을 허용해야 한다" do
    [ "john_doe", "kimchulsoo", "jane123", "ruby_user", "user_01", "john.doe" ].each do |username|
      user = build_user(username:, email: "test#{username.hash.abs}@example.com")
      user.valid?

      assert_empty user.errors[:username], "#{username} should be valid"
    end
  end

  test "email를 정규화해야 한다" do
    user = build_user(email: "  TEST@EXAMPLE.COM  ", username: "normalized_email")
    user.save!

    assert_equal "test@example.com", user.email
  end

  test "name은 그대로 저장된다" do
    user = build_user(email: "test@example.com", username: "raw_name", name: "  Test User  ")
    user.save!

    assert_equal "  Test User  ", user.name
  end

  test "admin?은 관리자 사용자에 대해 true를 반환해야 한다" do
    assert_predicate @admin, :admin?
    assert_not @user.admin?
    assert_not @korean_user.admin?
  end

  test "has_role?은 역할 보유 여부를 확인해야 한다" do
    assert @admin.has_role?(:admin)
    assert @user.has_role?(:user)
    assert_not @user.has_role?(:admin)
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
    user = build_user(email: "test@example.com", username: "blank_full_name", name: "")
    user.save!(validate: false)

    assert_equal "test", user.full_name
  end

  test "full_name은 이름이 nil일 때 이메일 접두사를 반환해야 한다" do
    user = build_user(email: "test@example.com", username: "nil_full_name", name: "Test")
    user.save!

    user.stub(:name, nil) do
      assert_equal "test", user.full_name
    end
  end

  test "올바른 비밀번호로 인증해야 한다" do
    user = User.create!(email: "auth@example.com", username: "auth_user", name: "Auth User", password: "secret123", confirmed_at: Time.current)

    assert user.valid_password?("secret123")
    assert_not user.valid_password?("wrong_password")
  end

  test "비밀번호를 안전하게 해시해야 한다" do
    password = "secret123"
    user = build_user(email: "secure@example.com", username: "secure_user", name: "Secure User", password:)
    user.save!

    assert_not_equal password, user.encrypted_password
    assert user.encrypted_password.start_with?("$2a$")
    assert user.valid_password?(password)
  end

  test "이름에 있는 한글 문자를 처리해야 한다" do
    [ "김철수", "박영희", "이민수", "정다혜", "최진우" ].each_with_index do |name, index|
      user = build_user(email: "korean#{index}@example.com", username: "korean_#{index}", name:)

      assert_predicate user, :valid?, "Korean name #{name} should be valid"
      user.save!

      assert_equal name, user.name
    end
  end

  test "매우 긴 유효한 이름을 처리해야 한다" do
    long_name = "김" + ("철" * 24) + "수"
    user = build_user(email: "longname@example.com", username: "long_name_user", name: long_name)

    assert_predicate user, :valid?, "Maximum length Korean name should be valid"
  end

  test "혼합 언어 이름을 처리해야 한다" do
    [ "John 김", "김 Smith", "Mary 박영희", "이민수 Johnson" ].each_with_index do |name, index|
      user = build_user(email: "mixed#{index}@example.com", username: "mixed_#{index}", name:)

      assert_predicate user, :valid?, "Mixed language name #{name} should be valid"
    end
  end

  test "숫자가 포함된 이름도 현재는 허용한다" do
    [ "김철수1", "John2", "사용자123", "User1" ].each do |name|
      assert_predicate build_user(email: "invalid#{name.hash.abs}@example.com", username: "name#{SecureRandom.hex(3)}", name:), :valid?
    end
  end

  test "created_at에 한국 시간대를 처리해야 한다" do
    Time.zone = "Asia/Seoul"
    user = User.create!(email: "timezone@example.com", username: "timezone_user", name: "시간대 테스트", password: "password123", confirmed_at: Time.current)

    assert_equal "Asia/Seoul", Time.zone.name
    assert_kind_of ActiveSupport::TimeWithZone, user.created_at
  end

  test "프로필 아바타 대표 이미지 URL을 반환해야 한다" do
    @user.avatar.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    assert_predicate @user, :avatar_attached?
    assert_match %r{\Ahttp://example\.com/rails/active_storage/disk/}, @user.avatar_url
  end

  test "프로필 아바타가 없으면 대표 이미지 URL은 nil이어야 한다" do
    assert_nil @user.avatar_url
  end

  test "프로필 아바타가 있으면 activitypub object에 icon을 포함해야 한다" do
    @user.avatar.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    object = @user.to_activitypub_object

    assert_equal "Image", object[:icon][:type]
    assert_equal "image/png", object[:icon][:mediaType]
    assert_match %r{\Ahttp://example\.com/rails/active_storage/disk/}, object[:icon][:url]
  end

  test "프로필 아바타가 없으면 activitypub object에 icon을 포함하지 않아야 한다" do
    object = @user.to_activitypub_object

    assert_not object.key?(:icon)
  end

  test "프로필 아바타를 제거할 수 있어야 한다" do
    @user.avatar.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    @user.remove_avatar!

    assert_not @user.avatar.attached?
    assert_nil @user.avatar_url
  end

  test "프로필 아바타를 제거하면 federails_actor extensions에서도 icon이 제거되어야 한다" do
    actor = federails_actors(:john_actor)

    @user.avatar.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )
    actor.reload

    assert actor.extensions.key?("icon")

    @user.remove_avatar!

    assert_equal({}, actor.reload.extensions)
  end

  test "with_role과 admins는 역할 기준으로 사용자를 찾는다" do
    assert_includes User.with_role(:admin), @admin
    assert_not_includes User.with_role(:admin), @user
    assert_includes User.admins, @admin
    assert_not_includes User.admins, @user
  end

  test "first_bot은 첫 번째 bot 사용자를 반환한다" do
    assert_not_nil User.first_bot
    assert User.first_bot.has_role?(:bot)
  end

  test "roles=는 문자열과 배열 모두에서 중복을 제거한다" do
    user = build_user(username: "roles_writer", email: "roles@example.com")

    user.roles = "user editor user"

    assert_equal [ "user", "editor" ], user.roles

    user.roles = [ "admin", "admin", "editor" ]

    assert_equal [ "admin", "editor" ], user.roles
  end

  test "bot 사용자는 follow를 자동 수락한다" do
    called_with = nil
    following = Object.new
    following.define_singleton_method(:accept!) do |**kwargs|
      called_with = kwargs
      true
    end

    @user.accept_follow(following, follow_activity: :follow_activity)

    assert_equal({ follow_activity: :follow_activity }, called_with)
  end

  test "bot이 아닌 사용자는 follow를 자동 수락하지 않는다" do
    user = users(:user_with_spaces)
    called = false
    following = Object.new
    following.define_singleton_method(:accept!) { |**| called = true }

    user.accept_follow(following, follow_activity: :follow_activity)

    assert_not called
  end

  test "이미지가 아닌 아바타는 유효하지 않다" do
    user = build_user(username: "text_avatar", email: "text-avatar@example.com")
    user.avatar.attach(io: StringIO.new("not image"), filename: "avatar.txt", content_type: "text/plain")

    assert_not user.valid?
    assert_includes user.errors[:avatar], "이미지 파일만 업로드할 수 있습니다"
  end

  test "avatar_url은 variant 처리 오류가 나면 nil을 반환한다" do
    @user.avatar.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    @user.stub(:avatar_variant, -> { raise StandardError, "variant failed" }) do
      assert_nil @user.avatar_url
    end
  end

  test "아바타가 없어도 remove_avatar!는 안전하다" do
    assert_nothing_raised do
      @user.remove_avatar!
    end
  end

  private

  def build_user(attributes = {})
    defaults = {
      email: "user#{SecureRandom.hex(4)}@example.com",
      username: "user_#{SecureRandom.hex(4)}",
      name: "테스트 사용자",
      password: "password123",
      confirmed_at: Time.current
    }

    User.new(defaults.merge(attributes))
  end
end
