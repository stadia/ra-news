# frozen_string_literal: true

require "test_helper"

class LongformPostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @other_user = users(:jane)
    @draft = posts(:longform_draft)
    @published = posts(:longform_published)
  end

  test "requires authentication to create a draft" do
    post longform_posts_url
    assert_redirected_to new_user_session_url
  end

  test "creates a longform draft and redirects to edit" do
    sign_in @user
    assert_difference -> { Post.longform.draft.count }, 1 do
      post longform_posts_url
    end
    draft = Post.longform.draft.order(:id).last
    assert_equal @user, draft.user
    assert_redirected_to edit_longform_post_url(draft)
  end

  test "renders edit page for owner draft" do
    sign_in @user
    get edit_longform_post_url(@draft)
    assert_response :success
    assert_select "h1", "긴 글 쓰기"
  end

  test "does not allow editing another user's draft" do
    @draft.update!(user: @other_user)
    sign_in @user
    get edit_longform_post_url(@draft)
    assert_redirected_to feed_url
  end

  test "autosaves draft fields" do
    sign_in @user
    patch longform_post_url(@draft), params: {
      post: { title: "자동 저장 제목", body: "<p>자동 저장 본문</p>", tag_list: "ruby, rails" }
    }, as: :json
    assert_response :success
    assert_equal "자동 저장 제목", @draft.reload.title
    assert_equal [ "ruby", "rails" ], @draft.tag_list
  end

  test "publishes a complete draft" do
    sign_in @user
    @draft.update!(title: "발행 제목", body: "<p>발행 본문</p>")
    patch publish_longform_post_url(@draft)
    assert_redirected_to post_url(@draft)
    assert_predicate @draft.reload, :published?
    assert_not_nil @draft.published_at
  end

  test "does not publish incomplete draft" do
    sign_in @user
    @draft.update!(title: "", body: "<p>본문</p>")
    patch publish_longform_post_url(@draft)
    assert_response :unprocessable_entity
    assert_predicate @draft.reload, :draft?
  end

  test "updates a published longform post" do
    sign_in @user
    patch longform_post_url(@published), params: {
      post: { title: "수정된 제목", body: "<p>수정된 본문</p>" }
    }
    assert_redirected_to post_url(@published)
    assert_equal "수정된 제목", @published.reload.title
  end
end
