# Post Model Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ActivityPub Note를 처리하는 Post 모델 추가 — 원문(parent 없음)과 댓글(parent 있음)을 하나의 모델로 표현

**Architecture:** Post는 `acts_as_nested_set`으로 자기 참조 트리 구조. `Federails::DataEntity`로 ActivityPub Note 연동. Comment와 달리 guest 없이 user 또는 federails_actor만 허용. Federails dispatch는 `handle_federated_object?`에서 `inReplyTo`가 없는 Note를 수락하여 Comment와 자연 분리.

**Tech Stack:** Rails 8.1, PostgreSQL, Federails (ActivityPub), awesome_nested_set

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `db/migrate/TIMESTAMP_create_posts.rb` | posts 테이블 생성 |
| Create | `app/models/post.rb` | Post 모델 (nested set, federation, validations) |
| Create | `test/fixtures/posts.yml` | 테스트 픽스쳐 |
| Create | `test/models/post_test.rb` | 모델 테스트 |

---

### Task 1: Migration 생성

**Files:**
- Create: `db/migrate/TIMESTAMP_create_posts.rb`

- [ ] **Step 1: migration 파일 생성**

```bash
bin/rails generate migration CreatePosts
```

- [ ] **Step 2: migration 내용 작성**

```ruby
class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.text :body, null: false
      t.references :user, foreign_key: true
      t.references :federails_actor, foreign_key: { to_table: :federails_actors }
      t.string :federated_url
      t.references :parent, foreign_key: { to_table: :posts }
      t.integer :lft, null: false
      t.integer :rgt, null: false
      t.integer :depth, default: 0, null: false
      t.integer :children_count, default: 0, null: false
      t.timestamps
    end

    add_index :posts, :lft
    add_index :posts, :rgt
    add_index :posts, [:parent_id, :created_at]
    add_index :posts, :federated_url, unique: true
  end
end
```

- [ ] **Step 3: migration 실행**

```bash
bin/rails db:migrate
```

Expected: 테이블 생성 성공

- [ ] **Step 4: Commit**

```bash
git add db/migrate/*_create_posts.rb db/schema.rb
git commit -m "feat: add posts table migration"
```

---

### Task 2: Post 모델 기본 구조 + 테스트

**Files:**
- Create: `app/models/post.rb`
- Create: `test/fixtures/posts.yml`
- Create: `test/models/post_test.rb`

- [ ] **Step 1: 픽스쳐 작성**

```yaml
# test/fixtures/posts.yml
root_post:
  body: "첫 번째 원문 포스트입니다."
  user: john
  lft: 1
  rgt: 4
  depth: 0

reply_post:
  body: "원문에 대한 답글입니다."
  user: jane
  parent_id: <%= ActiveRecord::FixtureSet.identify(:root_post) %>
  lft: 2
  rgt: 3
  depth: 1

remote_post:
  body: "리모트에서 온 포스트입니다."
  federails_actor: john_actor
  federated_url: "https://remote.example.com/notes/123"
  lft: 5
  rgt: 6
  depth: 0
```

- [ ] **Step 2: failing test 작성**

`test/models/post_test.rb` — validations, nested set, author 관련 테스트:

```ruby
# frozen_string_literal: true

require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @user = users(:john)
    @root_post = posts(:root_post)
    @reply_post = posts(:reply_post)
    @remote_post = posts(:remote_post)
  end

  # ========== Validation Tests ==========

  test "user가 있는 post는 유효하다" do
    post = Post.new(body: "테스트 포스트", user: @user)
    assert post.valid?, post.errors.full_messages.join(", ")
  end

  test "federails_actor가 있는 post는 유효하다" do
    actor = federails_actors(:john_actor)
    post = Post.new(body: "리모트 포스트", federails_actor: actor, federated_url: "https://example.com/notes/1")
    assert post.valid?, post.errors.full_messages.join(", ")
  end

  test "user도 federails_actor도 없으면 유효하지 않다" do
    post = Post.new(body: "고아 포스트")
    assert_not post.valid?
    assert post.errors[:base].any?
  end

  test "body는 필수" do
    post = Post.new(user: @user)
    assert_not post.valid?
    assert post.errors[:body].any?
  end

  test "body가 빈 문자열이면 유효하지 않다" do
    post = Post.new(body: "", user: @user)
    assert_not post.valid?
  end

  # ========== Nested Set Tests ==========

  test "root post는 parent가 없다" do
    assert_nil @root_post.parent_id
  end

  test "reply는 parent가 있다" do
    assert_equal @root_post.id, @reply_post.parent_id
  end

  test "root post는 children을 가진다" do
    assert_includes @root_post.children, @reply_post
  end

  # ========== Author Tests ==========

  test "author_name은 user name을 반환한다" do
    assert_equal @user.name, @root_post.author_name
  end

  test "author_name은 remote actor username을 반환한다" do
    assert_equal @remote_post.federails_actor.username, @remote_post.author_name
  end

  # ========== Federation Tests ==========

  test "federation_actor_entity는 user를 반환한다 (로컬)" do
    assert_equal @root_post.user, @root_post.federation_actor_entity
  end

  test "federation_actor_entity는 federails_actor를 반환한다 (리모트)" do
    assert_equal @remote_post.federails_actor, @remote_post.federation_actor_entity
  end

  test "should_federate?는 entity가 있으면 true" do
    assert @root_post.should_federate?
  end

  # ========== handle_federated_object? Tests ==========

  test "inReplyTo가 없는 Note를 수락한다" do
    hash = { "type" => "Note", "content" => "Hello" }
    assert Post.handle_federated_object?(hash)
  end

  test "inReplyTo가 있는 Note는 거부한다 (Comment가 처리)" do
    hash = { "type" => "Note", "inReplyTo" => "https://example.com/articles/1" }
    assert_not Post.handle_federated_object?(hash)
  end

  test "inReplyTo가 로컬 post를 가리키면 수락한다" do
    local_host = Rails.application.routes.default_url_options[:host] || "www.example.com"
    hash = { "type" => "Note", "inReplyTo" => "http://#{local_host}/posts/#{@root_post.id}" }
    assert Post.handle_federated_object?(hash)
  end

  test "inReplyTo가 리모트 post의 federated_url이면 수락한다" do
    hash = { "type" => "Note", "inReplyTo" => @remote_post.federated_url }
    assert Post.handle_federated_object?(hash)
  end

  # ========== from_activitypub_object Tests ==========

  test "from_activitypub_object는 body를 HTML strip한다" do
    hash = { "id" => "https://remote.example.com/notes/456", "content" => "<p>Hello <b>world</b></p>" }
    result = Post.from_activitypub_object(hash)
    assert_equal "Hello world", result[:body]
    assert_equal "https://remote.example.com/notes/456", result[:federated_url]
  end

  test "from_activitypub_object는 로컬 post URL에서 parent_id를 추출한다" do
    hash = {
      "id" => "https://remote.example.com/notes/999",
      "content" => "로컬 답글",
      "inReplyTo" => "http://www.example.com/posts/#{@root_post.id}"
    }
    result = Post.from_activitypub_object(hash)
    assert_equal @root_post.id.to_s, result[:parent_id]
  end

  test "from_activitypub_object는 inReplyTo로 parent를 찾는다" do
    hash = {
      "id" => "https://remote.example.com/notes/789",
      "content" => "답글",
      "inReplyTo" => @remote_post.federated_url
    }
    result = Post.from_activitypub_object(hash)
    assert_equal @remote_post.id, result[:parent_id]
  end
end
```

- [ ] **Step 3: 테스트 실행하여 실패 확인**

```bash
bin/rails test test/models/post_test.rb
```

Expected: 모든 테스트 실패 (Post 모델 없음)

- [ ] **Step 4: Post 모델 구현**

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

class Post < ApplicationRecord
  acts_as_nested_set

  belongs_to :user, optional: true

  validates :body, presence: true

  validate :validate_user_or_actor
  validate :validate_parent_post

  include Federails::DataEntity

  belongs_to :federails_actor, class_name: "Federails::Actor", optional: true
  # Federails::DataEntity가 추가하는 federails_actor presence 검증을 제거
  # (user 또는 federails_actor 중 하나만 있으면 됨)
  federails_actor_presence_validator = _validate_callbacks
    .map(&:filter)
    .find do |filter|
      filter.is_a?(ActiveRecord::Validations::PresenceValidator) &&
        filter.attributes == [ :federails_actor ]
    end
  skip_callback :validate, :before, federails_actor_presence_validator if federails_actor_presence_validator

  acts_as_federails_data handles: "Note",
    actor_entity_method: :federation_actor_entity,
    should_federate_method: :should_federate?

  on_federails_delete_requested -> { logger.info { "Federated post deletion requested #{id}" }; destroy! }

  def content
    body
  end

  def author_name
    user&.name || federails_actor&.username || "익명"
  end

  def author_host
    return if federails_actor.nil? || federails_actor.server.blank?

    "(#{federails_actor.server})"
  end

  def federation_actor_entity
    user || federails_actor
  end

  def should_federate?
    federation_actor_entity.present?
  end

  def to_activitypub_object
    custom = {}
    if parent.present?
      custom["inReplyTo"] = parent.federated_url || Rails.application.routes.url_helpers.post_url(parent)
    end
    Federails::DataTransformer::Note.to_federation(self, content: body, custom: custom)
  end

  private

  def validate_user_or_actor
    unless user_id.present? || federails_actor_id.present?
      errors.add(:base, "user 또는 federails_actor가 필요합니다")
    end
  end

  def validate_parent_post
    return unless parent_id.present?

    if parent.nil?
      errors.add(:parent_id, "원본 포스트를 찾을 수 없습니다.")
    end
  end

  class << self
    def from_activitypub_object(hash)
      in_reply_to = hash["inReplyTo"].to_s

      object = {
        federated_url: hash["id"],
        body: ActionController::Base.helpers.strip_tags(hash["content"]).squish
      }

      if in_reply_to.present?
        # 로컬 post ID로 찾기
        post_id = in_reply_to[%r{/posts/(\d+)}, 1]
        if post_id.present?
          object[:parent_id] = post_id
        else
          # federated_url로 찾기
          parent = Post.find_by(federated_url: in_reply_to)
          object[:parent_id] = parent.id if parent
        end
      end

      object
    end

    def handle_federated_object?(hash)
      in_reply_to = hash["inReplyTo"].to_s

      # inReplyTo가 없으면 원문 → 수락
      return true if in_reply_to.blank?

      # inReplyTo가 로컬 post를 가리키면 수락
      local_host = Rails.application.routes.default_url_options[:host]
      return true if local_host.present? && in_reply_to.include?(local_host) && in_reply_to.include?("/posts/")

      # inReplyTo가 기존 post의 federated_url이면 수락
      Post.exists?(federated_url: in_reply_to)
    end
  end
end
```

- [ ] **Step 5: route 추가** (federation에 필요)

`config/routes.rb`에 posts 리소스 추가:

```ruby
resources :posts, only: [:show]
```

- [ ] **Step 6: 테스트 실행하여 통과 확인**

```bash
bin/rails test test/models/post_test.rb
```

Expected: 모든 테스트 통과

- [ ] **Step 7: Commit**

```bash
git add app/models/post.rb test/models/post_test.rb test/fixtures/posts.yml config/routes.rb
git commit -m "feat: add Post model with nested set and ActivityPub federation"
```

---

### Task 3: Comment의 handle_federated_object? 수정

**중요:** Comment의 `handle_federated_object?`는 `in_reply_to.include?(local_host)`로 로컬 URL이면 무조건 `true` 반환. `/posts/` URL도 수락하므로 Post와 dispatch 충돌 발생. `/posts/` URL을 제외하도록 수정 필수.

**Files:**
- Modify: `app/models/comment.rb:172-180`
- Modify: `test/models/comment_test.rb`

- [ ] **Step 1: Comment가 post inReplyTo를 거부하는 테스트 추가**

```ruby
# test/models/comment_test.rb에 추가

test "inReplyTo가 /posts/를 가리키면 거부한다" do
  hash = { "inReplyTo" => "http://www.example.com/posts/1" }
  assert_not Comment.handle_federated_object?(hash)
end
```

- [ ] **Step 2: 테스트 실행하여 실패 확인**

```bash
bin/rails test test/models/comment_test.rb -n "test_inReplyTo가_/posts/를_가리키면_거부한다"
```

Expected: FAIL — 현재 코드는 로컬 host URL이면 무조건 true 반환

- [ ] **Step 3: Comment handle_federated_object? 수정**

`app/models/comment.rb` line 177을 변경:

```ruby
# Before:
return true if in_reply_to.include?(local_host)

# After:
return true if in_reply_to.include?(local_host) && !in_reply_to.include?("/posts/")
```

- [ ] **Step 4: 테스트 실행하여 통과 확인**

```bash
bin/rails test test/models/comment_test.rb
```

Expected: 모든 테스트 통과

- [ ] **Step 5: Commit**

```bash
git add app/models/comment.rb test/models/comment_test.rb
git commit -m "fix: Comment rejects inReplyTo targeting /posts/ URLs"
```
