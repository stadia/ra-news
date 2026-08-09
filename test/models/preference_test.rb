# frozen_string_literal: true

require "test_helper"

class PreferenceTest < ActiveSupport::TestCase
  test "신규 레코드에서도 OAuth dynamic accessor가 동작한다" do
    preference = Preference.new(name: "_new_record_oauth")

    preference.client_id = "id-from-new-record"

    assert_equal({ "client_id" => "id-from-new-record" }, preference.value)
    assert_equal "id-from-new-record", preference.client_id
  end

  test "name을 나중에 설정해도 OAuth dynamic accessor가 동작한다" do
    preference = Preference.new

    preference.name = "_assigned_later_oauth"
    preference.client_id = "id-after-name-assignment"

    assert_equal({ "client_id" => "id-after-name-assignment" }, preference.value)
    assert_equal "id-after-name-assignment", preference.client_id
  end

  test "신규 레코드에서 accessor로 설정한 값이 save 후에도 유지된다" do
    preference = Preference.new(name: "_persist_test_oauth")
    preference.client_id = "persisted-id"
    preference.client_secret = "persisted-secret"

    assert preference.save

    fresh = Preference.find(preference.id)

    assert_equal "persisted-id", fresh.client_id
    assert_equal "persisted-secret", fresh.client_secret
  end

  test "name에 nil을 할당하면 name이 nil이 되고 검증에 실패한다" do
    preference = Preference.create!(name: "_nil_assign_oauth", value: {})

    preference.name = nil

    assert_nil preference.name
    assert_not preference.valid?
  end

  test "ignore_hosts 설정이 배열이 아니면 빈 배열을 반환한다" do
    Preference.find_or_initialize_by(name: "ignore_hosts").update!(value: { "unexpected" => "value" })

    assert_equal [], Preference.ignore_hosts
  end

  test "ignore_hosts 배열의 비문자열 항목은 걸러진다" do
    Preference.find_or_initialize_by(name: "ignore_hosts").update!(value: [ "github.com", nil, 123 ])

    assert_equal [ "github.com" ], Preference.ignore_hosts
  end

  test "ignore_hosts 행이 없으면 빈 배열을 반환한다" do
    Preference.where(name: "ignore_hosts").destroy_all
    Rails.cache.clear

    assert_equal [], Preference.ignore_hosts
  end
end
