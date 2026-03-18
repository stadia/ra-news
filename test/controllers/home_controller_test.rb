# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "GET root renders successfully" do
    get root_path
    assert_response :success
  end

  test "GET about returns 200 with introduction content" do
    get about_path
    assert_response :success
    assert_select "h1", text: /Ruby-News 소개/
  end
end
