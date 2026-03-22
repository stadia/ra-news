# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "GET root renders successfully" do
    get root_path

    assert_response :success
  end

  test "GET root preloads liked articles for signed in user" do
    user = users(:john)
    Like.create!(liker: user, likeable: articles(:ruby_article), created_at: Time.current)
    sign_in_as(user)

    like_queries = capture_like_queries do
      get root_path
    end

    assert_response :success
    assert_equal 1, like_queries.size
  end

  test "GET about returns 200 with introduction content" do
    get about_path

    assert_response :success
    assert_select "h1", text: /Ruby-News 소개/
  end

  private

  def capture_like_queries
    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql]
      next unless sql&.include?('"likes"')
      next unless payload[:name] != "SCHEMA"

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      yield
    end

    queries
  end
end
