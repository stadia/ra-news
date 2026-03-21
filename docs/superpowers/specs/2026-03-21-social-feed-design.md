# Social Feed 리디자인

## 목적

Feed 목록을 X.com/Mastodon 같은 소셜 서비스 UX로 개편한다.

## 범위

1. **Post 작성 form** — 상단 textarea + 글자수 카운터
2. **무한 스크롤** — Turbo Frames + Stimulus + pagy_countless
3. **인라인 답글** — 각 post 아래 답글 form 토글, Post create로 처리
4. **상대 시간** — "3분 전" 스타일 표시

## 아키텍처

### Posts 컨트롤러

`PostsController#create` — 최상위 post와 답글 모두 처리.

- `parent_id` 파라미터 유무로 구분
- 성공: Turbo Stream으로 새 post 삽입
  - 최상위 → feed 상단 prepend
  - 답글 → 부모 post 아래 append + form 닫기
- 실패: Turbo Stream으로 에러 표시
- routes: `resources :posts, only: [:show, :create]`

### Feed View (Phlex)

**상단 Post Form:**
- textarea + 글자수 카운터 (`character_count_controller` 재사용)
- `data-turbo-frame` 또는 `turbo: true` form

**Post 카드:**
- 작성자 이름 + 상대 시간 (`time_ago_in_words`)
- body (whitespace-pre-wrap)
- "답글" 버튼 → inline form 토글 (`reply_form_controller`)
- 답글 수 (`children_count`)
- 들여쓰기로 스레드 깊이 표현 (depth 기반)

**무한 스크롤:**
- `pagy_countless`로 페이지네이션 (count 쿼리 제거)
- 마지막 post 아래 Turbo Frame (`loading: :lazy`, 다음 페이지 src)
- `infinite_scroll_controller` — Intersection Observer

### Turbo Stream 응답

```
POST /posts → turbo_stream 응답
  - 최상위: turbo_stream.prepend "posts", post_component
  - 답글: turbo_stream.append "replies_#{parent_id}", post_component
  - form 리셋: turbo_stream.replace "post_form", empty_form
```

### 파일 변경

| 파일 | 변경 |
|------|------|
| `config/routes.rb` | posts에 `:create` 추가 |
| `app/controllers/posts_controller.rb` | `create` 액션 추가 |
| `app/views/activities/feed.rb` | Post form, 무한 스크롤, 상대 시간, 답글 UI |
| `app/javascript/controllers/infinite_scroll_controller.js` | 신규 |
| `app/views/posts/create.turbo_stream.rb` | Turbo Stream 응답 (Phlex) |

## 미포함 (다음 작업)

- 좋아요(Like) 기능
- Boost/리포스트
- 아바타/프로필 이미지
