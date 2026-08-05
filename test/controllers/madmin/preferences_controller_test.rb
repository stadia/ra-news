# typed: true
# frozen_string_literal: true

require "test_helper"

class Madmin::PreferencesControllerTest < ActionDispatch::IntegrationTest
  test "admin can create OAuth preference with dynamic attributes" do
    sign_in_as users(:admin)

    assert_difference -> { Preference.count }, 1 do
      post madmin_preferences_path, params: {
        preference: {
          name: "_madmin_create_oauth",
          client_id: "madmin-client-id",
          client_secret: "madmin-client-secret"
        }
      }
    end

    preference = Preference.find_by!(name: "_madmin_create_oauth")

    assert_redirected_to madmin_preference_path(preference)
    assert_equal "madmin-client-id", preference.client_id
    assert_equal "madmin-client-secret", preference.client_secret
  end
end
