# typed: strong
# frozen_string_literal: true

require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "seeds create a confirmed admin user idempotently" do
    admin = users(:admin)
    admin.update_column(:confirmed_at, nil)

    assert_no_difference -> { User.where(email: "admin@example.com").count } do
      Rails.application.load_seed
    end

    admin.reload

    assert_includes admin.roles, "admin"
    assert_not_nil admin.confirmed_at

    assert_no_difference -> { User.where(email: "admin@example.com").count } do
      Rails.application.load_seed
    end
  end
end
