# typed: strong
# frozen_string_literal: true

require "test_helper"

class JwtDenylistTest < ActiveSupport::TestCase
  test "includes denylist revocation strategy" do
    assert_includes JwtDenylist.included_modules,
                    Devise::JWT::RevocationStrategies::Denylist
  end

  test "uses jwt_denylists table" do
    assert_equal "jwt_denylists", JwtDenylist.table_name
  end
end
