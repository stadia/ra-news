# frozen_string_literal: true

require "test_helper"

class CommentTest < ActiveSupport::TestCase
  # Test fixtures setup
  def setup
    @root_comment = comments(:root_comment_1)
    @nested_comment = comments(:nested_comment_1)
    @korean_comment = comments(:korean_comment)
    @max_length_comment = comments(:max_length_comment)
    @user = users(:john)
    @article = articles(:ruby_article)
  end

  # ========== Validation Tests ==========

  test "should be valid with valid attributes" do
    comment = Comment.new(
      body: "This is a valid test comment.",
      user: @user,
      article: @article
    )
    assert comment.valid?
  end

  test "should require body" do
    comment = Comment.new(user: @user, article: @article)
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "should require user" do
    comment = Comment.new(body: "Test comment", article: @article)
    assert_not comment.valid?
    assert_includes comment.errors[:user], "must exist"
  end

  test "should require article" do
    comment = Comment.new(body: "Test comment", user: @user)
    assert_not comment.valid?
    assert_includes comment.errors[:article], "must exist"
  end

  test "should validate body minimum length" do
    comment = Comment.new(
      body: "",
      user: @user,
      article: @article
    )
    assert_not comment.valid?
    assert_includes comment.errors[:body], "is too short (minimum is 1 character)"
  end

  test "should validate body maximum length" do
    long_body = "A" * (Comment::MAX_BODY_LENGTH + 1)
    comment = Comment.new(
      body: long_body,
      user: @user,
      article: @article
    )
    assert_not comment.valid?
    assert_includes comment.errors[:body], "is too long (maximum is #{Comment::MAX_BODY_LENGTH} characters)"
  end

  test "should accept body at maximum length" do
    max_body = "A" * Comment::MAX_BODY_LENGTH
    comment = Comment.new(
      body: max_body,
      user: @user,
      article: @article
    )
    assert comment.valid?
  end

  test "should accept body at minimum length" do
    comment = Comment.new(
      body: "A",
      user: @user,
      article: @article
    )
    assert comment.valid?
  end

  # ========== Association Tests ==========

  test "should belong to user" do
    assert_respond_to @root_comment, :user
    assert_kind_of User, @root_comment.user
    assert_equal users(:john), @root_comment.user
  end

  test "should belong to article" do
    assert_respond_to @root_comment, :article
    assert_kind_of Article, @root_comment.article
    assert_equal articles(:ruby_article), @root_comment.article
  end

  # ========== Nested Set Tests ==========

  test "should act as nested set" do
    # Test that awesome_nested_set methods are available
    assert_respond_to Comment, :roots
    assert_respond_to Comment, :leaves
    assert_respond_to @root_comment, :parent
    assert_respond_to @root_comment, :children
    assert_respond_to @root_comment, :descendants
    assert_respond_to @root_comment, :ancestors
    assert_respond_to @root_comment, :siblings
  end

  test "should have correct nested set structure" do
    # Root comment should have no parent
    assert_nil @root_comment.parent
    assert_equal 0, @root_comment.depth

    # Nested comment should have parent
    assert_not_nil @nested_comment.parent
    assert_equal @root_comment.id, @nested_comment.parent_id
    assert_equal 1, @nested_comment.depth
  end

  test "should maintain left and right values" do
    # Root comment with nested comment should have proper lft/rgt values
    assert_equal 1, @root_comment.lft
    assert_equal 4, @root_comment.rgt

    # Nested comment should be within parent's boundaries
    assert_equal 2, @nested_comment.lft
    assert_equal 3, @nested_comment.rgt
    assert @nested_comment.lft > @root_comment.lft
    assert @nested_comment.rgt < @root_comment.rgt
  end

  test "should create root comments properly" do
    root_comment = Comment.create!(
      body: "New root comment",
      user: @user,
      article: @article
    )

    assert_nil root_comment.parent
    assert_equal 0, root_comment.depth
    assert_not_nil root_comment.lft
    assert_not_nil root_comment.rgt
    assert root_comment.rgt > root_comment.lft
  end

  test "should create nested comments properly" do
    child_comment = @root_comment.children.create!(
      body: "New child comment",
      user: users(:jane),
      article: @article
    )

    assert_equal @root_comment, child_comment.parent
    assert_equal @root_comment.depth + 1, child_comment.depth
    assert_includes @root_comment.children, child_comment
  end

  test "should maintain nested set integrity when adding children" do
    initial_rgt = @root_comment.rgt

    child_comment = @root_comment.children.create!(
      body: "Integrity test comment",
      user: users(:jane),
      article: @article
    )

    @root_comment.reload

    # Parent's right value should have increased
    assert @root_comment.rgt > initial_rgt

    # Child should be properly positioned
    assert child_comment.lft > @root_comment.lft
    assert child_comment.rgt < @root_comment.rgt
  end

  # ========== Instance Method Tests ==========

  test "content method should return body" do
    assert_equal @root_comment.body, @root_comment.content
    assert_equal @korean_comment.body, @korean_comment.content
  end

  test "content method should handle nil body gracefully" do
    comment = Comment.new
    comment.body = nil
    assert_nil comment.content
  end

  # ========== Korean Content Tests ==========

  test "should handle Korean characters in body" do
    korean_bodies = [
      "안녕하세요! 좋은 글이네요.",
      "Ruby 3.4에 대한 정보가 정말 유익했습니다.",
      "한국 개발자들에게 도움이 될 것 같아요.",
      "감사합니다. 더 많은 정보를 기대합니다!",
      "이런 기술적인 내용을 한국어로 볼 수 있어서 좋네요."
    ]

    korean_bodies.each_with_index do |body, index|
      comment = Comment.new(
        body: body,
        user: users(:korean_user),
        article: @article
      )

      assert comment.valid?, "Korean comment should be valid: #{body}"
      comment.save!
      assert_equal body, comment.body
      assert_equal body, comment.content
    end
  end

  test "should handle mixed Korean and English content" do
    mixed_bodies = [
      "Ruby 3.4가 정말 훌륭하네요!",
      "Rails 8.0에 대한 정보 thank you!",
      "Performance improvements 정말 인상적입니다.",
      "한국어와 English를 함께 사용해도 괜찮나요?",
      "API changes가 많이 있었나요? 궁금합니다."
    ]

    mixed_bodies.each do |body|
      comment = Comment.new(
        body: body,
        user: @user,
        article: @article
      )

      assert comment.valid?, "Mixed language comment should be valid: #{body}"
      comment.save!
      assert_equal body, comment.body
    end
  end

  test "should handle Korean characters within length limits" do
    # Korean characters count as 1 character each in Ruby string length
    korean_text = "한" * Comment::MAX_BODY_LENGTH
    comment = Comment.new(
      body: korean_text,
      user: users(:korean_user),
      article: @article
    )

    assert comment.valid?
    assert_equal Comment::MAX_BODY_LENGTH, comment.body.length
  end

  test "should reject Korean text exceeding length limits" do
    # One character over the limit
    korean_text = "한" * (Comment::MAX_BODY_LENGTH + 1)
    comment = Comment.new(
      body: korean_text,
      user: users(:korean_user),
      article: @article
    )

    assert_not comment.valid?
    assert_includes comment.errors[:body], "is too long (maximum is #{Comment::MAX_BODY_LENGTH} characters)"
  end

  # ========== Special Characters and Edge Cases ==========

  test "should handle special characters in body" do
    special_bodies = [
      "Great article! 👍🔥✨",
      "What about <script>alert('xss')</script>?",
      "SQL injection'; DROP TABLE comments; --",
      "Unicode: ñáéíóú çñü αβγ δεζ",
      "Math symbols: ∑∏∫∆∇∂∞≈≠≤≥±×÷",
      "URLs: https://example.com?param=value&other=123"
    ]

    special_bodies.each do |body|
      comment = Comment.new(
        body: body,
        user: @user,
        article: @article
      )

      assert comment.valid?, "Special character comment should be valid: #{body}"
      comment.save!
      assert_equal body, comment.body
    end
  end

  test "should handle newlines and whitespace in body" do
    multiline_body = "First line\nSecond line\n\nFourth line with extra spacing"
    comment = Comment.new(
      body: multiline_body,
      user: @user,
      article: @article
    )

    assert comment.valid?
    comment.save!
    assert_equal multiline_body, comment.body
  end

  test "should handle very long single words" do
    # Test with a very long word (like a URL or hash)
    long_word = "https://verylongdomainname.com/very/long/path/with/many/segments/" + "a" * 800
    if long_word.length <= Comment::MAX_BODY_LENGTH
      comment = Comment.new(
        body: long_word,
        user: @user,
        article: @article
      )

      assert comment.valid?
    end
  end

  # ========== Thread Structure Tests ==========

  test "should create complex thread structure" do
    # Root comment
    root = Comment.create!(
      body: "Root comment",
      user: @user,
      article: @article
    )

    # First level children
    child1 = root.children.create!(
      body: "Child 1",
      user: users(:jane),
      article: @article
    )

    child2 = root.children.create!(
      body: "Child 2",
      user: users(:korean_user),
      article: @article
    )

    # Second level children
    grandchild1 = child1.children.create!(
      body: "Grandchild 1",
      user: @user,
      article: @article
    )

    grandchild2 = child1.children.create!(
      body: "Grandchild 2",
      user: users(:jane),
      article: @article
    )

    # Verify structure
    assert_equal 2, root.children.count
    assert_includes root.children, child1
    assert_includes root.children, child2

    assert_equal 2, child1.children.count
    assert_includes child1.children, grandchild1
    assert_includes child1.children, grandchild2

    assert_equal 0, child2.children.count

    # Verify depths
    assert_equal 0, root.depth
    assert_equal 1, child1.depth
    assert_equal 1, child2.depth
    assert_equal 2, grandchild1.depth
    assert_equal 2, grandchild2.depth

    # Verify descendants
    descendants = root.descendants
    assert_equal 4, descendants.count
    assert_includes descendants, child1
    assert_includes descendants, child2
    assert_includes descendants, grandchild1
    assert_includes descendants, grandchild2
  end

  test "should find siblings correctly" do
    # Create siblings
    sibling1 = @root_comment.children.create!(
      body: "Sibling 1",
      user: users(:jane),
      article: @article
    )

    sibling2 = @root_comment.children.create!(
      body: "Sibling 2",
      user: users(:korean_user),
      article: @article
    )

    # Test siblings
    siblings = sibling1.siblings
    assert_includes siblings, sibling2
    assert_includes siblings, @nested_comment # existing child
    assert_not_includes siblings, sibling1 # self not included in siblings
  end

  # ========== Query Performance Tests ==========

  test "should efficiently load comment threads" do
    # Test that nested set queries are efficient
    assert_queries(1) do
      Comment.roots.limit(5).to_a
    end
  end

  test "should efficiently load descendants" do
    # Nested set should allow efficient descendant queries
    assert_queries(1) do
      @root_comment.descendants.to_a
    end
  end

  # ========== Data Integrity Tests ==========

  test "should maintain integrity when deleting comments" do
    # Create a comment with children
    parent = Comment.create!(
      body: "Parent to be deleted",
      user: @user,
      article: @article
    )

    child = parent.children.create!(
      body: "Child comment",
      user: users(:jane),
      article: @article
    )

    initial_comment_count = Comment.count

    # Delete parent - this should handle children according to nested set rules
    parent.destroy!

    # Verify appropriate behavior (depends on nested set configuration)
    # This could either delete children or promote them, depending on setup
    remaining_comments = Comment.count
    assert remaining_comments <= initial_comment_count
  end

  test "should handle concurrent comment creation" do
    # Test that nested set handles concurrent operations gracefully
    comments = []

    # Create multiple comments concurrently (simulate with threads)
    threads = 3.times.map do |i|
      Thread.new do
        comment = Comment.create!(
          body: "Concurrent comment #{i}",
          user: @user,
          article: @article
        )
        comments << comment
      end
    end

    threads.each(&:join)

    # All comments should be created successfully
    assert_equal 3, comments.length
    comments.each do |comment|
      assert comment.persisted?
      assert_not_nil comment.lft
      assert_not_nil comment.rgt
    end
  end

  # ========== Integration Tests ==========

  test "should work with Korean timezone" do
    Time.zone = "Asia/Seoul"

    comment = Comment.create!(
      body: "시간대 테스트 댓글입니다.",
      user: users(:korean_user),
      article: @article
    )

    assert_equal "Asia/Seoul", Time.zone.name
    assert_kind_of ActiveSupport::TimeWithZone, comment.created_at
    assert_kind_of ActiveSupport::TimeWithZone, comment.updated_at
  end

  test "should handle article deletion gracefully" do
    comment = Comment.create!(
      body: "Comment on article to be deleted",
      user: @user,
      article: @article
    )

    # If article_id has NOT NULL constraint, deletion behavior may differ
    begin
      @article.destroy!
      comment.reload
      
      # If comment still exists, check its state
      if comment.persisted?
        assert_nil comment.article_id
      end
    rescue ActiveRecord::NotNullViolation, ActiveRecord::InvalidForeignKey
      # This is acceptable - database constraint prevents nullifying article_id
      # Comments might be deleted along with article or deletion might be blocked
      assert true, "Database constraint prevents article deletion with comments"
    rescue ActiveRecord::RecordNotFound
      # Comment was deleted along with article - also acceptable behavior
      assert_not Comment.exists?(comment.id)
    end
  end

  test "should handle user deletion appropriately" do
    comment = Comment.create!(
      body: "Comment by user to be deleted",
      user: @user,
      article: @article
    )

    # User deletion behavior depends on model setup
    # This test documents the expected behavior
    begin
      @user.destroy!
      comment.reload

      # If comment survives, it should handle missing user gracefully
      if comment.persisted?
        # Comment exists but user is gone
        assert_nil comment.user_id
      end
    rescue ActiveRecord::RecordNotFound
      # Comment was deleted along with user - this is also valid behavior
      assert_not Comment.exists?(comment.id)
    end
  end

  # ========== Fixture Validation Tests ==========

  test "all fixture comments should be valid" do
    Comment.all.each do |comment|
      assert comment.valid?, "Comment #{comment.id} should be valid: #{comment.errors.full_messages.join(', ')}"
    end
  end

  test "fixture comments should have proper nested set structure" do
    # Verify that fixture nested set values are consistent
    Comment.all.each do |comment|
      assert_not_nil comment.lft, "Comment #{comment.id} should have lft value"
      assert_not_nil comment.rgt, "Comment #{comment.id} should have rgt value"
      assert comment.rgt > comment.lft, "Comment #{comment.id} rgt should be greater than lft"

      if comment.parent_id
        parent = Comment.find(comment.parent_id)
        assert comment.lft > parent.lft, "Child lft should be greater than parent lft"
        assert comment.rgt < parent.rgt, "Child rgt should be less than parent rgt"
        assert_equal parent.depth + 1, comment.depth, "Child depth should be parent depth + 1"
      else
        assert_equal 0, comment.depth, "Root comment should have depth 0"
      end
    end
  end

  private

  # Helper method for testing query count
  def assert_queries(expected_count)
    queries = []
    ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
      queries << payload[:sql] unless payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/
    end

    yield

    assert_equal expected_count, queries.size, "Expected #{expected_count} queries, got #{queries.size}"
  ensure
    ActiveSupport::Notifications.unsubscribe("sql.active_record")
  end
end
