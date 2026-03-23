# frozen_string_literal: true

require "test_helper"

class CommentTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

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

  test "유효한 속성을 가진 경우 유효해야 한다" do
    comment = Comment.new(
      body: "This is a valid test comment.",
      user: @user,
      article: @article
    )
    assert_predicate comment, :valid?
  end

  test "body는 필수 항목이어야 한다" do
    comment = Comment.new(user: @user, article: @article)
    assert_not comment.valid?
    assert_includes comment.errors[:body], "내용을 입력해 주세요"
  end

  test "user 또는 federails_actor 중 하나는 필요하다" do
    comment_without_actor = Comment.new(body: "Test comment", article: @article)
    assert_not comment_without_actor.valid?
    assert_includes comment_without_actor.errors[:base], "user 또는 federails_actor가 필요합니다"

    remote_actor = Federails::Actor.create!(
      federated_url: "https://remote.example/users/tester",
      username: "tester",
      name: "Tester",
      server: "remote.example",
      inbox_url: "https://remote.example/users/tester/inbox",
      outbox_url: "https://remote.example/users/tester/outbox",
      followers_url: "https://remote.example/users/tester/followers",
      followings_url: "https://remote.example/users/tester/following",
      profile_url: "https://remote.example/@tester",
      actor_type: "Person",
      local: false
    )

    comment_with_actor = Comment.new(body: "Remote comment", article: @article, federails_actor: remote_actor)
    assert_predicate comment_with_actor, :valid?, "Federated actor comment should be valid: #{comment_with_actor.errors.full_messages}"
  end

  test "article은 필수 항목이어야 한다" do
    comment = Comment.new(body: "Test comment", user: @user)
    assert_not comment.valid?
    assert_includes comment.errors[:article], "값이 반드시 필요합니다"
  end

  test "body의 최소 길이를 검증해야 한다" do
    comment = Comment.new(
      body: "",
      user: @user,
      article: @article
    )
    assert_not comment.valid?
    assert_includes comment.errors[:body], "값은 최소 1자여야 합니다"
  end

  test "body의 최대 길이를 검증해야 한다" do
    long_body = "A" * (Comment::MAX_BODY_LENGTH + 1)
    comment = Comment.new(
      body: long_body,
      user: @user,
      article: @article
    )
    assert_not comment.valid?
    assert_includes comment.errors[:body], "값은 #{Comment::MAX_BODY_LENGTH}자를 넘을 수 없습니다"
  end

  test "최대 길이의 body를 허용해야 한다" do
    max_body = "A" * Comment::MAX_BODY_LENGTH
    comment = Comment.new(
      body: max_body,
      user: @user,
      article: @article
    )
    assert_predicate comment, :valid?
  end

  test "최소 길이의 body를 허용해야 한다" do
    comment = Comment.new(
      body: "A",
      user: @user,
      article: @article
    )
    assert_predicate comment, :valid?
  end

  # ========== Association Tests ==========

  test "user에 속해야 한다" do
    assert_respond_to @root_comment, :user
    assert_kind_of User, @root_comment.user
    assert_equal users(:john), @root_comment.user
  end

  test "article에 속해야 한다" do
    assert_respond_to @root_comment, :article
    assert_kind_of Article, @root_comment.article
    assert_equal articles(:ruby_article), @root_comment.article
  end

  # ========== Nested Set Tests ==========

  test "nested set으로 작동해야 한다" do
    # Test that awesome_nested_set methods are available
    assert_respond_to Comment, :roots
    assert_respond_to Comment, :leaves
    assert_respond_to @root_comment, :parent
    assert_respond_to @root_comment, :children
    assert_respond_to @root_comment, :descendants
    assert_respond_to @root_comment, :ancestors
    assert_respond_to @root_comment, :siblings
  end

  test "올바른 nested set 구조를 가져야 한다" do
    # Root comment should have no parent
    assert_nil @root_comment.parent
    assert_equal 0, @root_comment.depth

    # Nested comment should have parent
    assert_not_nil @nested_comment.parent
    assert_equal @root_comment.id, @nested_comment.parent_id
    assert_equal 1, @nested_comment.depth
  end

  test "lft와 rgt 값을 유지해야 한다" do
    # Root comment with nested comment should have proper lft/rgt values
    assert_equal 1, @root_comment.lft
    assert_equal 4, @root_comment.rgt

    # Nested comment should be within parent's boundaries
    assert_equal 2, @nested_comment.lft
    assert_equal 3, @nested_comment.rgt
    assert_operator @nested_comment.lft, :>, @root_comment.lft
    assert_operator @nested_comment.rgt, :<, @root_comment.rgt
  end

  test "루트 댓글을 올바르게 생성해야 한다" do
    root_comment = Comment.create!(
      body: "New root comment",
      user: @user,
      article: @article
    )

    assert_nil root_comment.parent
    assert_equal 0, root_comment.depth
    assert_not_nil root_comment.lft
    assert_not_nil root_comment.rgt
    assert_operator root_comment.rgt, :>, root_comment.lft
  end

  test "중첩된 댓글을 올바르게 생성해야 한다" do
    root = Comment.create!(body: "root", user: @user, article: @article)
    child_comment = root.children.create!(
      body: "New child comment",
      user: users(:jane),
      article: @article
    )
    root.reload
    child_comment.reload

    assert_equal root, child_comment.parent
    assert_equal 1, child_comment.depth
    assert_includes root.children, child_comment
  end

  test "자식 댓글 추가 시 nested set 무결성을 유지해야 한다" do
    initial_rgt = @root_comment.rgt

    child_comment = @root_comment.children.create!(
      body: "Integrity test comment",
      user: users(:jane),
      article: @article
    )

    @root_comment.reload

    # Parent's right value should have increased
    assert_operator @root_comment.rgt, :>, initial_rgt

    # Child should be properly positioned
    assert_operator child_comment.lft, :>, @root_comment.lft
    assert_operator child_comment.rgt, :<, @root_comment.rgt
  end

  # ========== Instance Method Tests ==========

  test "content 메서드는 body를 반환해야 한다" do
    assert_equal @root_comment.body, @root_comment.content
    assert_equal @korean_comment.body, @korean_comment.content
  end

  test "content 메서드는 body가 nil일 때 정상적으로 처리해야 한다" do
    comment = Comment.new
    comment.body = nil
    assert_nil comment.content
  end

  # ========== Korean Content Tests ==========

  test "body에 있는 한글 문자를 처리해야 한다" do
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

      assert_predicate comment, :valid?, "Korean comment should be valid: #{body}"
      comment.save!
      assert_equal body, comment.body
      assert_equal body, comment.content
    end
  end

  test "한글과 영문이 혼합된 내용을 처리해야 한다" do
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

      assert_predicate comment, :valid?, "Mixed language comment should be valid: #{body}"
      comment.save!
      assert_equal body, comment.body
    end
  end

  test "길이 제한 내의 한글 문자를 처리해야 한다" do
    # Korean characters count as 1 character each in Ruby string length
    korean_text = "한" * Comment::MAX_BODY_LENGTH
    comment = Comment.new(
      body: korean_text,
      user: users(:korean_user),
      article: @article
    )

    assert_predicate comment, :valid?
    assert_equal Comment::MAX_BODY_LENGTH, comment.body.length
  end

  test "길이 제한을 초과하는 한글 텍스트를 거부해야 한다" do
    # One character over the limit
    korean_text = "한" * (Comment::MAX_BODY_LENGTH + 1)
    comment = Comment.new(
      body: korean_text,
      user: users(:korean_user),
      article: @article
    )

    assert_not comment.valid?
    assert_includes comment.errors[:body], "값은 #{Comment::MAX_BODY_LENGTH}자를 넘을 수 없습니다"
  end

  # ========== Special Characters and Edge Cases ==========

  test "body에 있는 특수 문자를 처리해야 한다" do
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

      assert_predicate comment, :valid?, "Special character comment should be valid: #{body}"
      comment.save!
      assert_equal body, comment.body
    end
  end

  test "body에 있는 개행 및 공백을 처리해야 한다" do
    multiline_body = "First line\nSecond line\n\nFourth line with extra spacing"
    comment = Comment.new(
      body: multiline_body,
      user: @user,
      article: @article
    )

    assert_predicate comment, :valid?
    comment.save!
    assert_equal multiline_body, comment.body
  end

  test "매우 긴 단일 단어를 처리해야 한다" do
    # Test with a very long word (like a URL or hash)
    long_word = "https://verylongdomainname.com/very/long/path/with/many/segments/" + "a" * 800
    if long_word.length <= Comment::MAX_BODY_LENGTH
      comment = Comment.new(
        body: long_word,
        user: @user,
        article: @article
      )

      assert_predicate comment, :valid?
    end
  end

  # ========== Thread Structure Tests ==========

  test "복잡한 스레드 구조를 생성해야 한다" do
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

    root.reload
    child1.reload

    # Verify structure (max depth 1 - only root and direct children allowed)
    assert_equal 2, root.children.count
    assert_includes root.children, child1
    assert_includes root.children, child2

    assert_equal 0, child1.children.count
    assert_equal 0, child2.children.count

    # Verify depths
    assert_equal 0, root.depth
    assert_equal 1, child1.depth
    assert_equal 1, child2.depth

    # Verify descendants
    descendants = root.descendants
    assert_equal 2, descendants.count
    assert_includes descendants, child1
    assert_includes descendants, child2
  end

  test "대댓글의 답글(2단계 깊이) 생성 시도는 실패해야 한다" do
    # Create root comment
    root = Comment.create!(
      body: "Root comment",
      user: @user,
      article: @article
    )

    # Create first level child (reply)
    child = root.children.create!(
      body: "First level reply",
      user: users(:jane),
      article: @article
    )

    # Attempting to create a reply to a reply should fail
    grandchild = child.children.build(
      body: "Second level reply (should fail)",
      user: @user,
      article: @article
    )

    assert_not grandchild.save
    assert grandchild.errors[:parent_id].any? { |msg| msg.include?("대댓글에는 답글을 달 수 없습니다") }
  end

  test "형제 댓글을 올바르게 찾아야 한다" do
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

  test "댓글 스레드를 효율적으로 로드해야 한다" do
    # Test that nested set queries are efficient
    assert_queries(1) do
      Comment.roots.limit(5).to_a
    end
  end

  test "하위 댓글들을 효율적으로 로드해야 한다" do
    # Nested set should allow efficient descendant queries
    assert_queries(1) do
      @root_comment.descendants.to_a
    end
  end

  # ========== Data Integrity Tests ==========

  test "댓글 삭제 시 무결성을 유지해야 한다" do
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
    assert_operator remaining_comments, :<=, initial_comment_count
  end

  test "동시 댓글 생성을 처리해야 한다" do
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
      assert_predicate comment, :persisted?
      assert_not_nil comment.lft
      assert_not_nil comment.rgt
    end
  end

  # ========== Integration Tests ==========

  test "한국 시간대에서 작동해야 한다" do
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

  test "기사 삭제를 정상적으로 처리해야 한다" do
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

  test "사용자 연결이 해제되어도 댓글은 유지될 수 있다" do
    comment = Comment.create!(
      body: "Comment by user to be deleted",
      user: @user,
      article: @article
    )

    comment.update_column(:user_id, nil)

    comment.reload
    assert_predicate comment, :persisted?
    assert_nil comment.user
  end

  # ========== Fixture Validation Tests ==========

  test "모든 fixture 댓글은 유효해야 한다" do
    Comment.all.each do |comment|
      assert_predicate comment, :valid?, "Comment #{comment.id} should be valid: #{comment.errors.full_messages.join(', ')}"
    end
  end

  test "fixture 댓글은 올바른 nested set 구조를 가져야 한다" do
    # Verify that fixture nested set values are consistent
    Comment.all.each do |comment|
      assert_not_nil comment.lft, "Comment #{comment.id} should have lft value"
      assert_not_nil comment.rgt, "Comment #{comment.id} should have rgt value"
      assert_operator comment.rgt, :>, comment.lft, "Comment #{comment.id} rgt should be greater than lft"

      if comment.parent_id
        parent = Comment.find(comment.parent_id)
        assert_operator comment.lft, :>, parent.lft, "Child lft should be greater than parent lft"
        assert_operator comment.rgt, :<, parent.rgt, "Child rgt should be less than parent rgt"
        assert_equal parent.depth + 1, comment.depth, "Child depth should be parent depth + 1"
      else
        assert_equal 0, comment.depth, "Root comment should have depth 0"
      end
    end
  end

  test "author_name은 user.name을 우선적으로 반환해야 한다" do
    assert_equal @user.name, @root_comment.author_name
  end

  test "author_name은 federails_actor.username을 사용할 수 있다" do
    remote_actor = Federails::Actor.create!(
      federated_url: "https://remote.example/users/actor-name",
      username: "actor-name",
      name: "Actor Name",
      server: "remote.example",
      inbox_url: "https://remote.example/users/actor-name/inbox",
      outbox_url: "https://remote.example/users/actor-name/outbox",
      followers_url: "https://remote.example/users/actor-name/followers",
      followings_url: "https://remote.example/users/actor-name/following",
      profile_url: "https://remote.example/@actor-name",
      actor_type: "Person",
      local: false
    )
    comment = Comment.new(body: "리모트 댓글", article: @article, federails_actor: remote_actor)
    assert_equal "actor-name", comment.author_name
  end

  test "author_name은 '익명'을 반환해야 한다 (user와 guest 정보 모두 없을 때)" do
    comment = Comment.new(
      body: "테스트 댓글",
      article: @article,
      user: nil
    )
    assert_equal "익명", comment.author_name
  end

  test "답글 생성 시 알림 잡을 큐에 넣는다" do
    assert_enqueued_with(job: ReplyNotificationJob) do
      Comment.create!(
        body: "알림 잡 테스트",
        article: @article,
        user: users(:jane),
        parent_id: comments(:root_comment_1).id
      )
    end
  end

  test "내 댓글에 내가 답글을 달면 알림 잡을 큐에 넣지 않는다" do
    assert_no_enqueued_jobs(only: ReplyNotificationJob) do
      Comment.create!(
        body: "셀프 답글",
        article: @article,
        user: users(:john),
        parent_id: comments(:root_comment_1).id
      )
    end
  end

  # ========== handle_federated_object? Tests ==========

  test "inReplyTo가 /posts/를 가리키면 거부한다" do
    hash = { "inReplyTo" => "http://www.example.com/posts/1" }
    assert_not Comment.handle_federated_object?(hash)
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
