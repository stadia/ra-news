# Comment → Post 통합 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Comment 모델을 제거하고 Post 모델로 통합하여 Article 댓글과 독립 포스트를 하나의 모델로 관리한다.

**Architecture:** Post에 optional `article_id`를 추가. article_id가 있으면 댓글, 없으면 독립 포스트. comments 데이터를 posts로 마이그레이션 후 comments 테이블 삭제.

**Tech Stack:** Rails 8.1.3, Ruby 4.0.2, PostgreSQL, Phlex, Turbo Streams, acts_as_nested_set

---

### Task 1: 마이그레이션 — posts에 article_id 추가 및 articles counter_cache rename

**Files:**
- Create: `db/migrate/XXXXXX_add_article_id_to_posts.rb`

- [ ] **Step 1: 마이그레이션 생성**

```bash
bin/rails generate migration AddArticleIdToPosts
```

- [ ] **Step 2: 마이그레이션 작성**

생성된 파일을 다음과 같이 편집:

```ruby
class AddArticleIdToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :article_id, :bigint, null: true
    add_index :posts, :article_id
    add_foreign_key :posts, :articles

    rename_column :articles, :comments_count, :posts_count
  end
end
```

- [ ] **Step 3: 마이그레이션 실행**

```bash
bin/rails db:migrate
bin/rails db:migrate RAILS_ENV=test
```

- [ ] **Step 4: 커밋**

```bash
git add db/
git commit -m "feat: add article_id to posts and rename comments_count to posts_count"
```

---

### Task 2: Post 모델에 Article 댓글 기능 통합

**Files:**
- Modify: `app/models/post.rb`
- Modify: `app/models/article.rb`

- [ ] **Step 1: 테스트 작성 — Article 댓글 기본 기능**

`test/models/post_test.rb`에 추가:

```ruby
# ========== Article Comment Tests ==========

test "article_id가 있는 post는 댓글이다" do
  post = Post.new(body: "댓글 테스트", user: @user, article: articles(:ruby_article))

  assert_predicate post, :valid?
  assert_predicate post, :comment?
end

test "article_id가 없는 post는 독립 포스트다" do
  post = Post.new(body: "포스트 테스트", user: @user)

  assert_predicate post, :valid?
  assert_not post.comment?
end

test "comments 스코프는 article_id가 있는 것만 반환한다" do
  article = articles(:ruby_article)
  comment_post = Post.create!(body: "댓글", user: @user, article: article)

  assert_includes Post.comments, comment_post
  assert_not_includes Post.standalone, comment_post
  assert_includes Post.standalone, @root_post
  assert_not_includes Post.comments, @root_post
ensure
  comment_post&.destroy
end

test "reply는 parent가 있으면 parent를, 없으면 article을 반환한다" do
  article = articles(:ruby_article)
  comment_post = Post.create!(body: "댓글", user: @user, article: article)

  assert_equal article, comment_post.reply

  reply_to_comment = Post.create!(body: "답글", user: @user, article: article, parent: comment_post)

  assert_equal comment_post, reply_to_comment.reply
ensure
  reply_to_comment&.destroy
  comment_post&.destroy
end

test "author_name은 user 이름을 반환한다" do
  post = Post.new(body: "테스트", user: @user)

  assert_equal @user.name, post.author_name
end

test "author_name은 federails_actor가 있으면 username을 반환한다" do
  assert_equal @remote_post.federails_actor.username, @remote_post.author_name
end

test "author_name은 둘 다 없으면 익명을 반환한다" do
  post = Post.new(body: "테스트")

  assert_equal "익명", post.author_name
end
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
bin/rails test test/models/post_test.rb
```

Expected: `comment?`, `reply`, `author_name` 등 메서드 미정의로 실패

- [ ] **Step 3: Post 모델 수정**

`app/models/post.rb`에 추가/변경:

```ruby
belongs_to :article, optional: true, counter_cache: :posts_count

scope :comments, -> { where.not(article_id: nil) }
scope :standalone, -> { where(article_id: nil) }

#: () -> bool
def comment?
  article_id.present?
end

#: () -> (Post | Article)
def reply
  parent.present? ? parent : article
end

#: () -> String
def author_name
  user&.name || federails_actor&.username || "익명"
end

#: () -> String?
def author_host
  return if federails_actor.nil? || federails_actor&.server.blank?

  "(#{federails_actor&.server})"
end
```

- [ ] **Step 4: Article 모델 수정**

`app/models/article.rb`의 `has_many :comments` 를 변경:

```ruby
# 변경 전:
has_many :comments, dependent: :nullify

# 변경 후:
has_many :posts, dependent: :nullify
```

- [ ] **Step 5: 테스트 실행 — 통과 확인**

```bash
bin/rails test test/models/post_test.rb
```

- [ ] **Step 6: 커밋**

```bash
git add app/models/post.rb app/models/article.rb test/models/post_test.rb
git commit -m "feat: add article comment capabilities to Post model"
```

---

### Task 3: 답글 알림 기능을 Post로 이전

**Files:**
- Modify: `app/models/post.rb`
- Modify: `app/jobs/reply_notification_job.rb`

- [ ] **Step 1: 테스트 작성 — 답글 알림**

`test/models/post_test.rb`에 추가:

```ruby
# ========== Reply Notification Tests ==========

test "답글 작성 시 ReplyNotificationJob이 enqueue된다" do
  parent_post = Post.create!(body: "원글", user: @user)

  assert_enqueued_with(job: ReplyNotificationJob) do
    Post.create!(body: "답글", user: users(:jane), parent: parent_post)
  end
ensure
  parent_post&.destroy
end

test "parent가 없는 post는 알림을 보내지 않는다" do
  assert_no_enqueued_jobs(only: ReplyNotificationJob) do
    Post.create!(body: "원글", user: @user)
  end
end

test "자기 자신에게 답글을 달면 알림을 보내지 않는다" do
  parent_post = Post.create!(body: "원글", user: @user)

  assert_no_enqueued_jobs(only: ReplyNotificationJob) do
    Post.create!(body: "자기 답글", user: @user, parent: parent_post)
  end
ensure
  parent_post&.destroy
end

test "parent의 user가 없으면 알림을 보내지 않는다" do
  actor = federails_actors(:john_actor)
  parent_post = Post.create!(body: "리모트 원글", federails_actor: actor, federated_url: "https://example.com/notes/notif-test-#{SecureRandom.hex(4)}")

  assert_no_enqueued_jobs(only: ReplyNotificationJob) do
    Post.create!(body: "답글", user: @user, parent: parent_post)
  end
ensure
  parent_post&.destroy
end
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
bin/rails test test/models/post_test.rb -n /답글/
```

- [ ] **Step 3: Post 모델에 알림 콜백 추가**

`app/models/post.rb`에 추가:

```ruby
after_commit :enqueue_reply_notification, on: :create

private

#: () -> void
def enqueue_reply_notification
  unless parent_id.present?
    logger.debug { "ReplyNotification skip: post #{id} has no parent" }
    return
  end
  unless parent&.user_id.present?
    logger.debug { "ReplyNotification skip: parent post #{parent_id} has no local user" }
    return
  end
  if parent.user_id == user_id
    logger.debug { "ReplyNotification skip: self-reply by user #{user_id}" }
    return
  end

  logger.info { "ReplyNotification enqueue: post #{id} → parent #{parent_id} (user #{parent.user_id})" }
  ReplyNotificationJob.perform_later(parent.id, id)
end
```

- [ ] **Step 4: ReplyNotificationJob 수정 — Comment → Post**

`app/jobs/reply_notification_job.rb` 전체를 변경:

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

class ReplyNotificationJob < ApplicationJob
  queue_as :default

  #: (Integer parent_post_id, Integer reply_post_id) -> void
  def perform(parent_post_id, reply_post_id)
    parent_post = Post.includes(:user, :article).find(parent_post_id)
    reply_post = Post.includes(:user).find(reply_post_id)

    if parent_post.user.nil?
      logger.info "ReplyNotificationJob skip: parent post #{parent_post_id} has no user"
      return
    end
    if parent_post.user_id == reply_post.user_id
      logger.info "ReplyNotificationJob skip: self-reply by user #{parent_post.user_id}"
      return
    end

    logger.info "ReplyNotificationJob start: reply #{reply_post_id} → parent #{parent_post_id} (notify user #{parent_post.user_id})"
    notify_reply(parent_post:, reply_post:)
  end

  private

  def notify_reply(parent_post:, reply_post:)
    result = PushNotificationService.new.call(
      user: parent_post.user,
      title: "내 글에 새 답글이 달렸습니다",
      body: build_body(reply_post),
      path: notification_path(parent_post)
    )

    return if result.success?

    logger.info "ReplyNotificationJob skipped push delivery for post #{reply_post.id}: #{result.failure}"
  end

  def build_body(reply_post)
    "#{reply_post.author_name}: #{reply_post.body.to_s.truncate(80)}"
  end

  def notification_path(parent_post)
    if parent_post.article.present?
      Rails.application.routes.url_helpers.article_path(
        parent_post.article,
        anchor: "post_#{parent_post.id}"
      )
    else
      Rails.application.routes.url_helpers.post_path(parent_post)
    end
  end
end
```

- [ ] **Step 5: 테스트 실행 — 통과 확인**

```bash
bin/rails test test/models/post_test.rb -n /답글/
```

- [ ] **Step 6: 커밋**

```bash
git add app/models/post.rb app/jobs/reply_notification_job.rb test/models/post_test.rb
git commit -m "feat: add reply notification to Post model"
```

---

### Task 4: Federation 로직 통합 — from/to/handle activitypub

**Files:**
- Modify: `app/models/post.rb`
- Modify: `test/models/post_test.rb`

- [ ] **Step 1: 테스트 작성 — Article 댓글 Federation**

`test/models/post_test.rb`에 추가:

```ruby
# ========== Article Comment Federation Tests ==========

test "article 댓글의 to_activitypub_object는 article inReplyTo를 포함한다" do
  article = articles(:ruby_article)
  comment_post = Post.create!(body: "댓글", user: @user, article: article)

  result = comment_post.to_activitypub_object

  assert_includes result.to_s, "inReplyTo"
ensure
  comment_post&.destroy
end

test "handle_federated_object?는 로컬 article URL이면 true를 반환한다" do
  local_host = Rails.application.routes.default_url_options[:host] || "www.example.com"
  hash = { "type" => "Note", "inReplyTo" => "http://#{local_host}/articles/1" }

  assert Post.handle_federated_object?(hash)
end

test "handle_federated_object?는 기존 comment federated_url이면 true를 반환한다" do
  article = articles(:ruby_article)
  comment_post = Post.create!(body: "댓글", user: @user, article: article, federated_url: "https://remote.example.com/notes/comment-fed-test")

  hash = { "type" => "Note", "inReplyTo" => "https://remote.example.com/notes/comment-fed-test" }

  assert Post.handle_federated_object?(hash)
ensure
  comment_post&.destroy
end

test "from_activitypub_object는 article URL에서 article_id를 추출한다" do
  hash = {
    "id" => "https://remote.example.com/notes/article-comment",
    "content" => "기사 댓글",
    "inReplyTo" => "http://www.example.com/articles/1"
  }
  result = Post.from_activitypub_object(hash)

  assert_equal "1", result[:article_id].to_s
end
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
bin/rails test test/models/post_test.rb -n /article|Article/
```

- [ ] **Step 3: Post 모델 Federation 로직 통합**

`app/models/post.rb`의 `to_activitypub_object` 메서드를 수정:

```ruby
#: () -> Hash[String, untyped]
def to_activitypub_object
  custom = {}
  if parent.present?
    custom["inReplyTo"] = parent.federated_url || Rails.application.routes.url_helpers.post_url(parent)
  elsif article.present?
    custom["inReplyTo"] = article.federated_url || Rails.application.routes.url_helpers.article_url(article)
  end

  if respond_to?(:tag_list) && tag_list.any?
    custom["tag"] = tag_list.map do |name|
      { "type" => "Hashtag", "name" => "##{name}", "href" => "#{Rails.application.routes.default_url_options[:host]}/tags/#{name}" }
    end
  end

  if respond_to?(:media_attachments) && media_attachments.any?
    custom["attachment"] = media_attachments
  end

  Federails::DataTransformer::Note.to_federation(self, content: body, custom: custom)
end
```

`from_activitypub_object`를 수정:

```ruby
class << self
  #: (Hash[String, untyped]) -> Hash[Symbol, untyped]
  def from_activitypub_object(hash)
    in_reply_to = hash["inReplyTo"].to_s

    object = {
      federated_url: hash["id"],
      url: hash["url"],
      title: hash["summary"].presence,
      body: hash["content"].to_s.squish
    }

    if in_reply_to.present?
      # Article URL 파싱
      article_id = in_reply_to[%r{/articles/(\d+)}, 1]
      # Post URL 파싱
      post_id = in_reply_to[%r{/posts/(\d+)}, 1]
      # Comment URL 파싱 (하위 호환)
      comment_id = in_reply_to[%r{/comments/(\d+)}, 1]

      if article_id.present?
        object[:article_id] = article_id
      elsif post_id.present?
        object[:parent_id] = post_id
      elsif comment_id.present?
        # 기존 comment ID로 이전된 post 찾기
        parent = Post.find_by(id: comment_id)
        if parent
          object[:parent] = parent
          object[:article_id] = parent.article_id
        end
      else
        parent = Post.find_by(federated_url: in_reply_to)
        if parent
          object[:parent_id] = parent.id
          object[:article_id] = parent.article_id
        end
      end
    end

    # Mastodon 이미지 첨부 파싱
    attachments = Array(hash["attachment"]).select { |a| a.is_a?(Hash) && (a["type"] == "Document" || a["type"] == "Image") }
    object[:media_attachments] = attachments.map do |a|
      { "url" => a["url"], "mediaType" => a["mediaType"], "name" => a["name"] }.compact
    end

    # Mastodon 해시태그 파싱
    hashtags = Array(hash["tag"]).select { |t| t.is_a?(Hash) && t["type"] == "Hashtag" }
    object[:tag_list] = hashtags.map { |t| t["name"].to_s.delete_prefix("#") }.uniq.join(", ") if hashtags.any?

    object
  end

  #: (Hash[String, untyped]) -> bool
  def handle_federated_object?(hash)
    in_reply_to = hash["inReplyTo"].to_s

    # inReplyTo가 없으면 원문 → 수락
    return true if in_reply_to.blank?

    local_host = Rails.application.routes.default_url_options[:host]

    if local_host.present? && in_reply_to.include?(local_host)
      # 로컬 post 또는 article URL이면 수락
      return true if in_reply_to.include?("/posts/") || in_reply_to.include?("/articles/")
    end

    # 기존 post의 federated_url이면 수락
    Post.exists?(federated_url: in_reply_to)
  end
end
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

```bash
bin/rails test test/models/post_test.rb
```

- [ ] **Step 5: 커밋**

```bash
git add app/models/post.rb test/models/post_test.rb
git commit -m "feat: unify Comment federation logic into Post model"
```

---

### Task 5: 라우트 및 PostsController에 Article 댓글 액션 추가

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/controllers/posts_controller.rb`

- [ ] **Step 1: 테스트 작성 — Article 댓글 CRUD**

`test/controllers/posts_controller_test.rb`에 추가:

```ruby
# ========== Article Comment Tests ==========

test "should create article comment" do
  article = articles(:ruby_article)
  sign_in users(:john)

  assert_difference("Post.count") do
    post article_posts_url(article), params: { post: { body: "새 댓글" } }, as: :turbo_stream
  end

  new_post = Post.last

  assert_equal article.id, new_post.article_id
  assert_response :success
end

test "should create article reply" do
  article = articles(:ruby_article)
  parent_post = Post.create!(body: "부모 댓글", user: users(:john), article: article)
  sign_in users(:jane)

  assert_difference("Post.count") do
    post article_posts_url(article), params: { post: { body: "답글", parent_id: parent_post.id } }, as: :turbo_stream
  end

  assert_response :success
ensure
  parent_post&.destroy
end

test "should destroy own article comment" do
  article = articles(:ruby_article)
  user = users(:john)
  comment_post = Post.create!(body: "삭제 테스트", user: user, article: article)
  sign_in user

  assert_difference("Post.count", -1) do
    delete article_post_url(article, comment_post), as: :turbo_stream
  end

  assert_response :success
ensure
  comment_post&.reload&.destroy rescue nil
end

test "should not destroy other user article comment" do
  article = articles(:ruby_article)
  comment_post = Post.create!(body: "남의 댓글", user: users(:john), article: article)
  sign_in users(:jane)

  assert_no_difference("Post.count") do
    delete article_post_url(article, comment_post), as: :turbo_stream
  end
ensure
  comment_post&.destroy
end
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
bin/rails test test/controllers/posts_controller_test.rb
```

Expected: `article_posts_url` 미정의로 실패

- [ ] **Step 3: 라우트 변경**

`config/routes.rb`에서:

```ruby
# 변경 전:
resources :articles, only: %i[index show new create] do
  resource :like, only: [ :create, :destroy ], controller: :likes, defaults: { likeable_type: "Article" }
  resources :comments, only: %i[create destroy] do
  end
end

# 변경 후:
resources :articles, only: %i[index show new create] do
  resource :like, only: [ :create, :destroy ], controller: :likes, defaults: { likeable_type: "Article" }
  resources :posts, only: %i[create destroy]
end
```

- [ ] **Step 4: PostsController 수정 — Article 댓글 지원**

`app/controllers/posts_controller.rb` 전체를 변경:

```ruby
# frozen_string_literal: true

class PostsController < ApplicationController
  include RateLimiting

  before_action :authenticate_user!, only: [ :create, :destroy ]
  before_action :set_article, only: [ :create, :destroy ], if: -> { params[:article_id].present? }
  before_action :set_post, only: [ :destroy ]
  before_action :check_rate_limit, only: [ :create ]

  def create
    if @article
      create_article_comment
    else
      create_standalone_post
    end
  end

  def destroy
    if @post.user != current_user
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "권한이 없습니다." }
        format.turbo_stream { head :unauthorized }
      end
      return
    end

    @article = @post.article
    @post.destroy

    if @article
      load_article_comments
      respond_to do |format|
        format.html { redirect_to @article, notice: "댓글이 삭제되었습니다." }
        format.turbo_stream { render "posts/destroy_article_comment" }
      end
    else
      respond_to do |format|
        format.html { redirect_to feed_path, notice: "포스트가 삭제되었습니다." }
        format.turbo_stream
      end
    end
  end

  private

  def create_article_comment
    @post = @article.posts.build(post_params)
    @post.user = current_user

    respond_to do |format|
      if @post.save
        load_article_comments
        format.html { redirect_to @article, notice: "댓글이 성공적으로 작성되었습니다." }
        format.turbo_stream { render "posts/create_article_comment" }
      else
        load_article_comments
        format.html { redirect_to @article, alert: "댓글 작성에 실패했습니다." }
        format.turbo_stream { render "posts/create_article_comment", status: :unprocessable_entity }
      end
    end
  end

  def create_standalone_post
    @post = current_user.posts.build(post_params)

    respond_to do |format|
      if @post.save
        format.turbo_stream { render Views::Posts::CreateTurboStream.new(post: @post) }
        format.html { redirect_to feed_path }
      else
        format.turbo_stream { render Views::Posts::CreateTurboStream.new(post: @post), status: :unprocessable_entity }
        format.html { redirect_to feed_path, alert: "포스트 작성에 실패했습니다." }
      end
    end
  end

  def set_article
    @article = Article.kept.find_by_slug(params[:article_id]) || Article.kept.find_by(id: params[:article_id])
    raise ActiveRecord::RecordNotFound if @article.nil?
  end

  def set_post
    @post = Post.find(params[:id])
  end

  def load_article_comments
    @comments = @article.posts.includes(:user)
  end

  def post_params
    params.expect(post: [ :body, :parent_id ])
  end
end
```

- [ ] **Step 5: 테스트 실행 — 통과 확인**

```bash
bin/rails test test/controllers/posts_controller_test.rb
```

- [ ] **Step 6: 커밋**

```bash
git add config/routes.rb app/controllers/posts_controller.rb test/controllers/posts_controller_test.rb
git commit -m "feat: add article comment CRUD to PostsController"
```

---

### Task 6: Article 댓글 Turbo Stream 뷰 생성

**Files:**
- Create: `app/views/posts/create_article_comment.turbo_stream.erb`
- Create: `app/views/posts/destroy_article_comment.turbo_stream.erb`

- [ ] **Step 1: create_article_comment turbo_stream 뷰 생성**

`app/views/posts/create_article_comment.turbo_stream.erb`:

```erb
<% if @post.persisted? %>
  <% if @post.parent_id.present? %>
    <%= turbo_stream.append "post_replies_#{@post.parent_id}" do %>
      <%= render(
        Components::Comments::Comment.new(
          comment: @post,
          article: @article,
          depth: @post.depth,
          children: {},
        ),
      ) %>
    <% end %>
  <% else %>
    <%= turbo_stream.prepend "comments_list" do %>
      <%= render(
        Components::Comments::Comment.new(
          comment: @post,
          article: @article,
          depth: 0,
          children: {},
        ),
      ) %>
    <% end %>
  <% end %>

  <%= turbo_stream.update "comments_header" do %>
    <%= render(Components::Comments::CommentHeader.new(comments: @comments)) %>
  <% end %>

  <%= turbo_stream.update "comment_form" do %>
    <%= render(Components::Comments::CommentForm.new(article: @article, comment: Post.new)) %>
  <% end %>
<% else %>
  <% if @post.parent_id.present? && @post.parent.present? %>
    <%= turbo_stream.replace "reply_form_#{@post.parent_id}" do %>
      <%= render(Components::Comments::CommentReplyForm.new(article: @article, comment: @post, parent_comment: @post.parent, visible: true)) %>
    <% end %>
  <% else %>
    <%= turbo_stream.update "comment_form" do %>
      <%= render(Components::Comments::CommentForm.new(article: @article, comment: @post)) %>
    <% end %>
  <% end %>
<% end %>
```

- [ ] **Step 2: destroy_article_comment turbo_stream 뷰 생성**

`app/views/posts/destroy_article_comment.turbo_stream.erb`:

```erb
<%= turbo_stream.remove dom_id(@post) %>

<%= turbo_stream.update "comments_header" do %>
  <%= render(Components::Comments::CommentHeader.new(comments: @comments)) %>
<% end %>
```

- [ ] **Step 3: 커밋**

```bash
git add app/views/posts/
git commit -m "feat: add article comment turbo stream views"
```

---

### Task 7: Comment 컴포넌트를 Post 호환으로 수정

**Files:**
- Modify: `app/components/comments/comment.rb`
- Modify: `app/components/comments/comments.rb`
- Modify: `app/components/comments/comment_form.rb`
- Modify: `app/components/comments/comment_reply_form.rb`

이 태스크에서는 Comment 컴포넌트들이 Post 객체도 받을 수 있도록 수정한다. Post에 `author_name`, `author_host`, `comment?` 등이 이미 추가되어 있으므로, 주요 변경은 URL 헬퍼와 모델 참조뿐이다.

- [ ] **Step 1: CommentForm 수정 — Post 모델 호환**

`app/components/comments/comment_form.rb`에서:

```ruby
# 변경: Comment.new → Post.new, article_comments_path → article_posts_path, Comment::MAX_BODY_LENGTH 참조 제거

# comment_form_fields 메서드의 form_with URL:
# 변경 전:
form_with(model: [ @article, @comment ], url: article_comments_path(@article), ...)

# 변경 후:
form_with(model: [ @article, @comment ], url: article_posts_path(@article), ...)

# character_count 관련 MAX_BODY_LENGTH 참조를 제거하고 data attribute도 제거
# body_field의 maxlength도 제거
```

- [ ] **Step 2: CommentReplyForm 수정**

`app/components/comments/comment_reply_form.rb`에서:

```ruby
# reply_form_fields 메서드의 form_with URL:
# 변경 전:
form_with(model: [ @article, @comment ], url: article_comments_path(@article), ...)

# 변경 후:
form_with(model: [ @article, @comment ], url: article_posts_path(@article), ...)

# MAX_BODY_LENGTH 참조 제거
```

- [ ] **Step 3: Comment 컴포넌트의 delete_button URL 수정**

`app/components/comments/comment.rb`에서:

```ruby
# delete_button 메서드:
# 변경 전:
button_to(article_comment_path(@article, @comment), ...)

# 변경 후:
button_to(article_post_path(@article, @comment), ...)
```

또한 `reply_form_section`에서:

```ruby
# 변경 전:
render Components::Comments::CommentReplyForm.new(
  article: @article,
  comment: ::Comment.new,
  parent_comment: @comment
)

# 변경 후:
render Components::Comments::CommentReplyForm.new(
  article: @article,
  comment: ::Post.new,
  parent_comment: @comment
)
```

- [ ] **Step 4: Comment DOM ID를 post 기반으로 변경**

`app/components/comments/comment.rb`의 `children_section`:

```ruby
# 변경 전:
div(id: "comment_replies_#{@comment.id}", ...)

# 변경 후:
div(id: "post_replies_#{@comment.id}", ...)
```

turbo_stream 뷰에서도 맞춰서 `comment_replies_` → `post_replies_` 변경 (Task 6의 뷰에 이미 반영)

- [ ] **Step 5: 테스트 실행**

```bash
bin/rails test
```

- [ ] **Step 6: 커밋**

```bash
git add app/components/comments/
git commit -m "refactor: update Comment components to work with Post model"
```

---

### Task 8: ArticlesController 및 Article Show 뷰 수정

**Files:**
- Modify: `app/controllers/articles_controller.rb`
- Modify: `app/views/articles/show.rb`
- Modify: `app/components/home/article.rb`
- Modify: `app/components/articles/article.rb`

- [ ] **Step 1: ArticlesController 수정**

`app/controllers/articles_controller.rb`에서 Comment 참조를 Post로 변경:

```ruby
# 변경 전:
@comments = @article.comments.includes(:user)
@comment = Comment.new

# 변경 후:
@comments = @article.posts.includes(:user)
@comment = Post.new
```

- [ ] **Step 2: Article Show 뷰 수정**

`app/views/articles/show.rb`에서 `render_comments_section`의 `CommentForm`에 전달하는 comment를 Post로:

기존 코드는 이미 `@comment` 변수를 사용하므로 ArticlesController에서 `Post.new`로 변경하면 자동 적용됨.

- [ ] **Step 3: Article 카드 컴포넌트의 comments_count 참조 수정**

`app/components/home/article.rb:65`:

```ruby
# 변경 전:
plain article.comments_count.to_s

# 변경 후:
plain article.posts_count.to_s
```

`app/components/articles/article.rb:67`:

```ruby
# 변경 전:
plain @article.comments_count.to_s

# 변경 후:
plain @article.posts_count.to_s
```

- [ ] **Step 4: 테스트 실행**

```bash
bin/rails test
```

- [ ] **Step 5: 커밋**

```bash
git add app/controllers/articles_controller.rb app/views/articles/show.rb app/components/home/article.rb app/components/articles/article.rb
git commit -m "refactor: update ArticlesController and views to use Post instead of Comment"
```

---

### Task 9: RecentCommentsSidebar 및 Dashboard 수정

**Files:**
- Modify: `app/components/recent_comments_sidebar.rb`
- Modify: `app/controllers/home_controller.rb`
- Modify: `app/controllers/madmin/dashboard_controller.rb`

- [ ] **Step 1: HomeController 수정**

`app/controllers/home_controller.rb`에서:

```ruby
# 변경 전:
@recent_comments = Comment.joins(:article).includes(:article, :user, :federails_actor).where(article: { deleted_at: nil }).order(created_at: :desc).limit(10)

# 변경 후:
@recent_comments = Post.where.not(article_id: nil).joins(:article).includes(:article, :user, :federails_actor).where(article: { deleted_at: nil }).order(created_at: :desc).limit(10)
```

- [ ] **Step 2: Dashboard Controller 수정**

`app/controllers/madmin/dashboard_controller.rb`에서:

```ruby
# 변경 전:
@recent_comments = Comment.includes(:article, :user).order(created_at: :desc).limit(5)

# 변경 후:
@recent_comments = Post.comments.includes(:article, :user).order(created_at: :desc).limit(5)
```

- [ ] **Step 3: Dashboard의 comments_count 참조 확인 및 수정**

Dashboard에서 `@comments_count` 변수가 있다면 수정:

```ruby
# 변경 전:
@comments_count = Comment.count

# 변경 후:
@comments_count = Post.comments.count
```

- [ ] **Step 4: 테스트 실행**

```bash
bin/rails test
```

- [ ] **Step 5: 커밋**

```bash
git add app/controllers/home_controller.rb app/controllers/madmin/dashboard_controller.rb app/components/recent_comments_sidebar.rb
git commit -m "refactor: update sidebar and dashboard to use Post.comments"
```

---

### Task 10: Madmin Comment 리소스 제거 및 Post 리소스 업데이트

**Files:**
- Delete: `app/madmin/resources/comment_resource.rb`
- Delete: `app/controllers/madmin/comments_controller.rb`
- Modify: `config/routes.rb` (madmin 라우트에서 comments 제거)

- [ ] **Step 1: Madmin comment 라우트 확인 및 제거**

`config/routes.rb`에서 madmin comments 라우트를 찾아 제거:

```bash
grep -n 'comment' config/routes.rb
```

madmin 블록 내의 comments 리소스를 제거한다.

- [ ] **Step 2: 파일 삭제**

```bash
git rm app/madmin/resources/comment_resource.rb
git rm app/controllers/madmin/comments_controller.rb
```

- [ ] **Step 3: 테스트 실행**

```bash
bin/rails test
```

- [ ] **Step 4: 커밋**

```bash
git add -A
git commit -m "refactor: remove Madmin comment resource"
```

---

### Task 11: Comment 모델/컨트롤러/뷰/테스트 삭제 및 데이터 마이그레이션

**Files:**
- Delete: `app/models/comment.rb`
- Delete: `app/controllers/comments_controller.rb`
- Delete: `app/views/comments/`
- Delete: `test/models/comment_test.rb`
- Delete: `test/controllers/comments_controller_test.rb`
- Create: `db/migrate/XXXXXX_migrate_comments_to_posts.rb`

- [ ] **Step 1: 데이터 마이그레이션 생성**

```bash
bin/rails generate migration MigrateCommentsToPosts
```

- [ ] **Step 2: 마이그레이션 작성**

```ruby
class MigrateCommentsToPosts < ActiveRecord::Migration[8.1]
  def up
    # comments 데이터를 posts로 이전
    execute <<~SQL
      INSERT INTO posts (body, user_id, federails_actor_id, federated_url, article_id, parent_id, lft, rgt, depth, children_count, created_at, updated_at)
      SELECT body, user_id, federails_actor_id, federated_url, article_id, parent_id, lft, rgt, depth, children_count, created_at, updated_at
      FROM comments
    SQL

    # parent_id 재매핑: 이전된 comment의 parent_id는 comments 테이블 ID를 참조하므로
    # 새로운 posts ID로 업데이트 필요
    # 이를 위해 임시 매핑 테이블 사용
    execute <<~SQL
      UPDATE posts
      SET parent_id = mapping.new_id
      FROM (
        SELECT c.id AS old_id, p.id AS new_id
        FROM comments c
        JOIN posts p ON p.federated_url = c.federated_url
        WHERE c.federated_url IS NOT NULL
      ) AS mapping
      WHERE posts.parent_id = mapping.old_id
      AND posts.article_id IS NOT NULL
    SQL

    # counter cache 재계산
    execute <<~SQL
      UPDATE articles
      SET posts_count = (SELECT COUNT(*) FROM posts WHERE posts.article_id = articles.id)
    SQL

    drop_table :comments
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

> **Note:** parent_id 재매핑은 데이터에 따라 조정이 필요할 수 있다. 프로덕션 실행 전 스테이징에서 반드시 검증할 것.

- [ ] **Step 3: Comment 파일 삭제**

```bash
git rm app/models/comment.rb
git rm app/controllers/comments_controller.rb
git rm app/views/comments/create.turbo_stream.erb
git rm app/views/comments/destroy.turbo_stream.erb
git rm test/models/comment_test.rb
git rm test/controllers/comments_controller_test.rb
git rm test/fixtures/comments.yml
```

- [ ] **Step 4: posts fixture에 article 댓글 추가**

`test/fixtures/posts.yml`에 추가:

```yaml
# Article comments (migrated from comments)
article_comment_1:
  body: "이것은 매우 유익한 기사입니다."
  user: john
  article: ruby_article
  lft: 7
  rgt: 10
  depth: 0

article_comment_reply:
  body: "동감합니다!"
  user: korean_user
  article: ruby_article
  parent_id: <%= ActiveRecord::FixtureSet.identify(:article_comment_1) %>
  lft: 8
  rgt: 9
  depth: 1
```

- [ ] **Step 5: 마이그레이션 실행**

```bash
bin/rails db:migrate
bin/rails db:migrate RAILS_ENV=test
```

- [ ] **Step 6: 전체 테스트 실행**

```bash
bin/rails test
```

- [ ] **Step 7: 남아있는 Comment 참조 정리**

```bash
grep -rn 'Comment\|comment_count' --include='*.rb' app/ | grep -v 'comment?' | grep -v '#.*comment' | grep -v 'recent_comments'
```

남아있는 참조가 있으면 수정한다.

- [ ] **Step 8: 커밋**

```bash
git add -A
git commit -m "feat: migrate comments data to posts and remove Comment model"
```

---

### Task 12: Stimulus 컨트롤러 정리

**Files:**
- Check: `app/javascript/controllers/comment_form_controller.js`

- [ ] **Step 1: comment_form stimulus 컨트롤러 확인**

```bash
cat app/javascript/controllers/comment_form_controller.js
```

이 컨트롤러가 `post_form_controller.js`와 동일한 기능(`reset`)이라면 제거하고 `post_form` 컨트롤러를 사용하도록 CommentForm 컴포넌트를 수정한다.

다르다면 유지하거나 통합한다.

- [ ] **Step 2: 정리 후 커밋**

```bash
git add -A
git commit -m "refactor: clean up stimulus controllers after comment→post unification"
```

---

### Task 13: 최종 검증

- [ ] **Step 1: 전체 테스트 실행**

```bash
bin/rails test
```

- [ ] **Step 2: 남아있는 Comment 참조 검색**

```bash
grep -rn 'Comment' --include='*.rb' app/ lib/ test/ config/
grep -rn 'comment' --include='*.rb' config/routes.rb
```

- [ ] **Step 3: Rails validate 실행**

```bash
bin/rails 'ai:tool[validate]' files=app/models/post.rb,app/controllers/posts_controller.rb level=rails
```

- [ ] **Step 4: 최종 커밋**

```bash
git add -A
git commit -m "chore: final cleanup after comment→post unification"
```
