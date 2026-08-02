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

  test "ignore_hosts 설정이 배열이 아니면 빈 배열을 반환한다" do
    Preference.find_or_initialize_by(name: "ignore_hosts").update!(value: { "unexpected" => "value" })

    assert_equal [], Preference.ignore_hosts
  end
end
