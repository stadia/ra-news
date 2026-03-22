# frozen_string_literal: true

require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @article = articles(:ruby_article)
    @user = users(:john)
    @comment = comments(:root_comment_1)
  end

  test "POST create requires authentication" do
    assert_no_difference("Comment.count") do
      post article_comments_path(@article), params: { comment: { body: "비로그인 댓글" } }
    end

    assert_redirected_to new_session_path
  end

  test "POST create creates comment for authenticated user" do
    sign_in_as(@user)

    assert_difference("Comment.count", 1) do
      post article_comments_path(@article), params: { comment: { body: "로그인 댓글" } }, as: :turbo_stream
    end

    assert_response :success
    assert_equal @user, Comment.order(:id).last.user
  end

  test "DELETE destroy requires authentication" do
    delete article_comment_path(@article, @comment)

    assert_redirected_to new_session_path
  end
end
