# frozen_string_literal: true

require "test_helper"

class ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders resend confirmation form" do
    get new_user_confirmation_path

    assert_response :success
    assert_select "h1", text: I18n.t("devise.confirmations.new.title")
    assert_select 'input[name="user[email]"][autocomplete="email"][required]'
    assert_select "button", text: I18n.t("devise.confirmations.new.submit")
  end

  test "POST create with invalid email rerenders form with submitted value" do
    post user_confirmation_path, params: {
      user: { email: "invalid-email" }
    }

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
    assert_select 'input[name="user[email]"][value="invalid-email"]'
    assert_select "#error_explanation li", minimum: 1
  end

  test "GET show with invalid token rerenders resend form with errors" do
    get user_confirmation_path, params: {
      confirmation_token: "invalid-token"
    }

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
    assert_select 'input[name="user[email]"][autocomplete="email"]'
  end
end
