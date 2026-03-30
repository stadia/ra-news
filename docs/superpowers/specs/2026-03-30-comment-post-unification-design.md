# Comment → Post 모델 통합 설계

## 개요

Comment 모델을 제거하고 Post 모델로 통합한다. Post에 `article_id`를 추가하여 Article 댓글 역할도 수행하게 한다.

## 결정 사항

- 통합 방식: Post에 `article_id` 추가 (STI 미사용)
- 기존 comments 데이터: 마이그레이션으로 posts 테이블로 이전
- 대댓글 제한: 무제한 중첩 허용
- body 길이 제한: 없음
- 답글 알림: 모든 Post 답글로 확대
- counter_cache: articles.comments_count → articles.posts_count로 rename

## 1. 데이터베이스

### 마이그레이션 순서

1. **posts 테이블에 article_id 추가**
   - `article_id` (bigint, nullable, indexed, foreign key)

2. **comments 데이터를 posts로 이전**
   - 매핑: body, user_id, federails_actor_id, parent_id, article_id, federated_url, lft, rgt, depth, children_count, created_at, updated_at
   - parent_id는 이전 후 posts 내부 ID로 재매핑 필요

3. **articles 테이블 counter_cache rename**
   - `comments_count` → `posts_count`

4. **comments 테이블 삭제**

## 2. Post 모델

### 추가 사항

```ruby
belongs_to :article, optional: true, counter_cache: :posts_count

scope :comments, -> { where.not(article_id: nil) }
scope :standalone, -> { where(article_id: nil) }

def comment?
  article_id.present?
end

def reply
  parent.present? ? parent : article
end
```

### Comment에서 이전하는 로직

- `enqueue_reply_notification` — 모든 Post 답글에 적용
- `to_activitypub_object` — article 댓글일 때 `inReplyTo`에 article/parent 반영
- `from_activitypub_object` — article URL 파싱 로직 통합
- `handle_federated_object?` — article 관련 조건 통합
- `author_name`, `author_host` — Post에도 동일하게 추가
- `validate_user_or_actor` — 이미 양쪽에 존재, 유지

### 제거 대상

- Comment의 `validate_parent_comment` (1단계 제한) — 무제한 중첩이므로 불필요
- Comment의 body 길이 제한 — 제거

## 3. 컨트롤러

### CommentsController → PostsController 통합

- `POST /articles/:article_id/posts` → posts#create (article 댓글)
- `DELETE /articles/:article_id/posts/:id` → posts#destroy (article 댓글)
- 기존 `POST /posts`, `GET /posts/:id` 유지

### 라우트

```ruby
resources :articles do
  resources :posts, only: [:create, :destroy]
end

resources :posts, only: [:create, :show]
```

### Madmin

- Madmin::CommentsController 제거
- Madmin에서 Post로 통합 관리 (article_id 필터 가능)

## 4. 뷰

### 파일 변경

- `comments/create.turbo_stream.erb` → PostsController에서 처리
- `comments/destroy.turbo_stream.erb` → PostsController에서 처리
- `Components::Comments::*` → `Components::Posts::*`로 rename
  - CommentHeader → PostHeader (또는 통합)
  - CommentForm → PostForm (통합)
  - CommentReplyForm → PostReplyForm (통합)
  - Comment → Post (통합)

### DOM ID 변경

- `comment_` 접두사 → `post_` 접두사
- `comments_list` → `posts_list`
- `comments_header` → `posts_header`
- `comment_form` → `post_form`
- `comment_replies_` → `post_replies_`
- `reply_form_` → `reply_form_` (유지 가능)

### Stimulus

- `comment_form` 컨트롤러 → `post_form`으로 통합 (동일 기능)

## 5. 서비스 / 잡

- `ReplyNotificationJob` — Comment 참조를 Post로 변경
- Federation 관련 — Comment 핸들링을 Post로 통합

## 6. 테스트

- `test/models/comment_test.rb` 68개 테스트 → `test/models/post_test.rb`로 통합
- `test/controllers/comments_controller_test.rb` → `test/controllers/posts_controller_test.rb`에 article 댓글 테스트 추가
- 기존 post_test.rb 19개 테스트 유지

## 7. 삭제 대상 파일

- `app/models/comment.rb`
- `app/controllers/comments_controller.rb`
- `app/controllers/madmin/comments_controller.rb`
- `app/views/comments/`
- `app/components/comments/` (있다면)
- `test/models/comment_test.rb`
- `test/controllers/comments_controller_test.rb`
- Madmin comment 관련 리소스 파일
