# frozen_string_literal: true

require "test_helper"

class SocialControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    sign_in_as(@admin)
  end

  test "GET provider_callback redirects with alert when state mismatches" do
    get "/social/xcom/callback?code=auth_code&state=wrong_state"

    assert_redirected_to madmin_social_index_path
  end
end
