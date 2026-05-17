# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "GET root renders successfully" do
    get root_path

    assert_response :success
    assert_select "aside.recent-comments-sidebar"
    assert_select "aside.tags-sidebar"
    assert_select "a[href='#{tag_path(tags(:ruby_tag).name)}']", text: /#ruby/
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

  test "GET root avoids per-record queries for thumbnails and recent comment authors" do
    queries = capture_queries do
      get root_path
    end

    assert_response :success
    assert_empty queries.grep(/FROM "active_storage_blobs" WHERE "active_storage_blobs"\."id" =/)
    assert_empty queries.grep(/FROM "active_storage_attachments" WHERE "active_storage_attachments"\."record_id" =/)
    assert_operator queries.grep(/FROM "users" WHERE "users"\."id" =/).size, :<=, 1
  end

  test "GET about returns 200 with introduction content" do
    get about_path

    assert_response :success
    assert_select "h1", text: /Ruby-News 소개/
  end

  private

  def capture_like_queries(&block)
    capture_queries(&block).select { |sql| sql.include?('"likes"') }
  end

  def capture_queries(&block)
    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql]
      next unless sql
      next if payload[:name] == "SCHEMA"

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      block.call
    end

    queries
  end
end
