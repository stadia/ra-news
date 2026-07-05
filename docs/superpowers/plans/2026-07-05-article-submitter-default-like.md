# Article Submitter Default Like Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 일반 Article 등록 폼으로 생성된 Article에 제출한 `current_user`의 Like를 원자적으로 생성한다.

**Architecture:** `ArticlesController#create`가 Article 저장과 기존 `User#like!` 호출을 단일 Active Record 트랜잭션으로 조정한다. Article 소유권과 후속 `ArticleJob` 동작은 유지하며 모델 콜백이나 새 서비스 계층은 추가하지 않는다.

**Tech Stack:** Rails 8.1, Active Record, Devise `current_user`, Minitest integration tests, PostgreSQL

---

### Task 1: 폼 제출자의 기본 Like 생성

**Files:**
- Modify: `test/controllers/articles_controller_test.rb`
- Modify: `app/controllers/articles_controller.rb:147-166`

- [ ] **Step 1: 실패하는 컨트롤러 통합 테스트 작성**

```ruby
test "POST create automatically likes the article as the submitting user" do
  user = users(:john)
  sign_in_as(user)

  assert_difference("Article.count", 1) do
    assert_difference("Like.count", 1) do
      post articles_path, params: { article: { url: "https://example.com/submitted-by-user" } }
    end
  end

  article = Article.find_by!(url: "https://example.com/submitted-by-user")
  assert_redirected_to article_path(article)
  assert_equal User.first_bot, article.user
  assert user.likes?(article)
  assert_equal 1, article.reload.likers_count
end
```

- [ ] **Step 2: 테스트가 기대한 이유로 실패하는지 확인**

Run: `bin/rails test test/controllers/articles_controller_test.rb -n /automatically_likes/`

Expected: Like 수가 증가하지 않아 `assert_difference("Like.count", 1)`가 실패한다.

- [ ] **Step 3: 저장과 Like 생성을 트랜잭션으로 구현**

`ArticlesController#create`에서 저장 성공 여부를 다음과 같이 계산한다.

```ruby
created = Article.transaction do
  next false unless @article.save

  current_user.like!(@article)
  true
end
```

기존 `if @article.save` 분기를 `if created`로 바꾸고, 성공한 경우에만 기존 `ArticleJob.perform_later`와 redirect를 실행한다.

- [ ] **Step 4: 영향 파일을 Rails 규칙으로 검증**

Run: `bin/rails 'ai:tool[validate]' files=app/controllers/articles_controller.rb,test/controllers/articles_controller_test.rb level=rails`

Expected: 오류 없음.

- [ ] **Step 5: 대상 테스트와 연관 테스트 실행**

Run: `bin/rails test test/controllers/articles_controller_test.rb test/controllers/likes_controller_test.rb test/models/like_test.rb`

Expected: 모든 테스트 통과.

- [ ] **Step 6: 전체 품질 게이트 실행**

Run: `bin/rake quality`

Expected: line coverage, branch coverage, Flog method, Flog class 게이트가 모두 통과한다.

- [ ] **Step 7: graphify 코드 그래프 갱신**

Run: `python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"`

Expected: `graphify-out/` 코드 그래프 갱신 성공.
