# 장문 Post 설계

## 배경

현재 Ruby News의 `Post`는 독립 단문과 기사 댓글을 함께 담당한다. 사용자는 마스토돈 같은 단문 작성뿐 아니라 블로그나 미디엄처럼 긴 글을 쓰고 싶지만, 첫 단계에서 완전한 블로그 도메인을 새로 만들기에는 범위가 크다.

따라서 첫 구현은 기존 `Post`를 확장한다. 단문 경험은 유지하면서 장문 작성에 필요한 제목, 초안, 자동 저장, 발행 후 수정, 요약 기반 ActivityPub 연합을 추가한다. 이후 필요하면 별도 블로그 모델로 분리할 수 있도록 데이터와 UI 경계를 명확히 둔다.

## 목표

- 기존 단문 작성창에서 `장문 쓰기`로 전용 편집 화면에 진입한다.
- 장문은 제목과 본문을 가진다.
- 장문 제목은 장문 모드에서만 필수다.
- 장문은 초안 자동 저장, 발행, 발행 후 수정을 지원한다.
- 본인은 기존 초안과 발행 장문을 편집기로 다시 열어 수정할 수 있다.
- 본인은 초안과 발행 장문을 삭제(soft discard)할 수 있다.
- 삭제된 글은 본인 프로필의 휴지통 전용 탭에서 확인하고, 복원하거나 영구 삭제할 수 있다.
- 본문 편집은 Lexxy 리치 텍스트 편집기를 앱용 Phlex 컴포넌트로 감싸서 사용한다.
- 이미지 업로드는 첫 버전에 포함하지 않고, 외부 이미지 URL 삽입만 허용한다.
- 장문 ActivityPub 발행은 전체 본문이 아니라 본문 앞부분 요약과 원문 URL을 보낸다.
- 기존 프로필 글 목록(`/@:username/posts`)에 발행 장문을 함께 표시한다.

## 비목표

- 별도 블로그/에세이 모델 신설
- 시리즈, 예약 발행, 대표 이미지, 이미지 업로드
- AI 요약 생성
- 기존 단문과 댓글 작성 흐름의 동작 변경

## 도메인 모델

`Post`에 유형과 발행 상태를 추가한다. 두 값은 Rails enum으로 모델에 선언하고, 데이터베이스에는 정수 컬럼으로 저장한다.

- `post_type` enum
  - `short`: 기존 독립 단문
  - `longform`: 장문
  - `comment`: 기사 댓글
- `status` enum
  - `draft`: 자동 저장되지만 공개 피드와 ActivityPub에 노출하지 않는다.
  - `published`: 피드, 프로필 글 목록, 원문 페이지, ActivityPub에 노출한다.

소프트 삭제(휴지통/복원)는 **장문 전용**이다. 단문(`short`)과 기사 댓글(`comment`)은 기존대로 hard delete한다(로컬 삭제도, 인바운드 연합 Delete도 `destroy`). Post에는 기존 `Article`/`Site`/`NotificationChannel`과 동일하게 `include Discard::Model`과 `self.discard_column = :deleted_at`를 두지만, `discard`를 호출하는 경로는 장문 삭제뿐이다. `visible` 스코프는 `published`이면서 `kept`(삭제되지 않음)인 글만 반환한다(`where(status: :published).kept`). 이렇게 하면 발행 상태(draft/published)와 삭제 상태(kept/discarded)가 직교하는 두 축으로 분리된다.

추가 필드는 다음을 예상한다.

- `title`: 장문 제목
- `published_at`: 장문 발행 시각

마이그레이션은 기존 데이터를 다음처럼 백필한다.

- `article_id`가 있는 기존 글은 `comment`
- `article_id`가 없는 기존 글은 `short`
- 기존 글의 `status`는 `published`
- 새 단문과 댓글의 기본 `status`는 `published`
- 새 장문 초안의 초기 `status`는 `draft`

검증 규칙은 다음과 같다.

- `short`와 `comment`의 `body` 필수 규칙은 유지한다.
- `longform` 초안은 자동 저장을 위해 `title` 또는 `body` 중 하나가 있으면 저장할 수 있다.
- `longform`이 `published` 상태가 될 때 `title`과 `body`는 모두 필수다.
- `longform`이 `published` 상태가 될 때 `published_at`을 기록한다.
- `short`와 `comment`에는 제목을 요구하지 않는다.
- 완전히 비어 있는 장문 초안은 저장하지 않는다.

## 작성 흐름

기존 단문 작성 컴포넌트에 `장문 쓰기` 버튼을 추가한다. 이 버튼은 장문 초안을 만들고 전용 편집 화면으로 이동한다.

전용 편집 화면은 승인된 혼합형 레이아웃을 따른다.

- 상단: 뒤로가기, 자동 저장 상태, 미리보기, 발행 버튼
- 중앙: 제목 입력, Lexxy 리치 텍스트 편집기
- 하단: 태그, 공개 상태, 초안/발행 상태 요약
- 발행 버튼: 최종 확인 대화상자

자동 저장 대상은 제목, 본문, 태그, 외부 이미지 URL 삽입 결과다. 자동 저장은 Turbo/Stimulus 기반으로 구현하되, 서버는 일반 `PATCH` 엔드포인트로도 동작해야 한다.

## Lexxy 사용

Lexxy는 이미 앱 작성 폼에서 사용 중이다.

- `Components::Posts::PostForm`
- `Components::Comments::CommentForm`
- `Components::Comments::CommentReplyForm`

장문 편집기는 이 기존 앱 폼 패턴의 `f.lexxy_rich_textarea` 사용을 기준으로 확장한다. 관리 화면용 `app/madmin/fields/lexxy_editor_field.rb`는 별도 래퍼로 존재하지만, 장문 편집기의 주된 기준은 현재 단문과 댓글 작성 폼이다.

장문 전용 앱 컴포넌트는 기존 Lexxy 로딩, CSS, 이벤트 패턴을 재사용하되 설정만 장문 작성에 맞게 조정한다.

- 장문 편집용 툴바 설정
- 링크 삽입
- 외부 이미지 URL 삽입
- 업로드 버튼 제외
- 기존 시맨틱 토큰과 RubyUI/Phlex 스타일 유지

## 공개 노출

기존 공개 프로필 글 목록(`/@:username/posts`)은 발행 콘텐츠 노출 용도로 유지한다. 장문 글쓰기 관리는 소유자 전용 `장문` 탭으로 분리한다(위 "수정과 삭제" 참고).

노출 규칙은 다음과 같다.

- 발행된 장문은 공개 프로필 글 목록과 피드에 함께 표시한다(소유자의 `장문` 탭에도 관리용으로 함께 표시).
- 장문 카드는 제목, 자동 요약, 원문 링크 중심으로 렌더링한다.
- 초안과 `discarded` 글은 공개 프로필 목록과 피드 어디에도 표시하지 않는다. 공개 피드 쿼리도 `visible`(published)로 제한해 초안·삭제 글이 새지 않도록 한다.
- 초안·휴지통은 공개 `글`/`댓글` 탭에 섞지 않고, 소유자 전용 `장문` 탭에만 모아 둔다.
- 단문 카드는 기존 표시 방식을 유지한다.

장문 원문 페이지는 기존 `PostsController#show` 흐름을 확장하되, 장문 루트 글은 스레드 중심 화면보다 읽기 중심 레이아웃을 우선한다. 답글 스레드는 원문 하단에 연결한다.

## 수정과 삭제

작성 직후뿐 아니라 나중에 다시 편집기로 들어가 수정하고, 더 이상 필요 없는 글을 삭제할 수 있어야 한다. 장문 글쓰기 관리(초안·발행 장문·휴지통)는 흩어 두지 않고, 본인 프로필의 **소유자 전용 `장문` 탭** 한 곳에 모은다.

`장문` 탭은 하위 구분 세 개를 가진다.

- **작성 중 초안**: 발행 전 초안. 삭제(휴지통으로 보낸) 초안은 제외한다(`longform.draft.kept`). 각 초안은 편집기로 여는 링크와 삭제 컨트롤을 가진다.
- **발행됨**: 발행된 장문. 공개 피드·프로필 글 목록에도 그대로 노출되며, 이 관리 탭에서는 수정·삭제 진입점을 함께 제공한다.
- **휴지통**: 삭제(soft discard)된 장문. 복원·영구삭제 컨트롤을 가진다.

수정 진입점은 다음과 같다.

- `장문` 탭의 초안/발행 항목에서 편집기로 진입한다. 본인의 발행 장문 원문 페이지에도 `수정` 진입점을 둔다. 모두 기존 `edit_longform_post` 편집기로 이동하며, `update`/autosave 흐름을 그대로 재사용한다.
- 수정 링크는 Turbo hover prefetch(`data-turbo-prefetch`)를 꺼서 편집기 페이지를 미리 가져오지 않게 한다(`data-turbo-prefetch="false"`).
- `장문` 탭과 그 모든 진입점은 본인에게만 노출한다. 공개 프로필 `글`/`댓글` 탭에는 초안·휴지통을 더 이상 섞지 않는다.

삭제는 `Discard::Model`을 사용한 soft discard로 처리한다.

- 초안과 발행 장문 모두 본인만 삭제할 수 있다.
- 삭제는 확인 단계를 거친 뒤 `discard`(또는 `discard!`)를 호출해 `deleted_at`를 기록한다. DB 레코드는 유지한다.
- 삭제된 글은 `kept` 스코프에서 빠지므로 `visible`에서도 제외되어 피드·프로필 목록·원문 페이지에 더 이상 노출되지 않는다.
- 삭제 진입점은 수정 진입점과 같은 위치(초안 목록, 발행 장문 원문 페이지)에 둔다.

### 공개 가시성 강제

`discard`로 레코드가 남고 인바운드 연합 삭제도 `discard!`로 처리하므로, 모든 공개 read 경로가 `kept`/`visible`를 강제해야 삭제된 글이 새지 않는다.

- 원문 페이지(`PostsController#show`)는 `visible`(published.kept)만 공개로 서빙한다. 비공개 초안은 소유자 본인만 미리 볼 수 있고, discarded 글은 공개로 서빙하지 않는다(소유자는 휴지통에서 확인).
- 기사 댓글, 프로필 댓글 탭, 홈 최근 댓글 등 댓글 read 경로는 `kept`를 적용한다. `article.posts_count` 같은 카운터도 discarded 댓글을 세지 않도록 정합을 맞춘다.
- 인바운드 연합 기사 답글은 `post_type: :comment`로 저장해 `comments` 스코프에 포함되게 한다.

### 휴지통

삭제된 장문은 위 `장문` 탭의 **휴지통 하위 구분**에서 관리한다(별도 탭으로 두지 않는다).

- 본인에게만 보이며, `discarded`(not kept) 장문 목록을 보여준다.
- 각 항목은 복원과 영구 삭제를 제공한다.
- 복원(undiscard)은 `deleted_at`을 지워 글을 원래 상태(초안/발행)로 되돌린다. 발행이었던 글을 복원하면 ActivityPub `Undo`(또는 재연합)로 원격에도 되살린다. 초안은 연합한 적이 없으므로 복원 시 연합 활동을 발행하지 않는다.
- 영구 삭제(hard destroy)는 레코드를 실제로 제거하고, 발행이었던 글이면 Federails의 `after_destroy` 경로로 `Delete`(Tombstone)를 발행한다.

## ActivityPub

기존 단문은 지금처럼 전체 본문을 `Note`로 발행한다.

장문은 전체 본문을 연합하지 않는다.

- `content`: 본문 앞부분에서 자동 추출한 요약
- `url`: 사이트 원문 URL
- 제목: ActivityPub 객체의 제목에 해당하는 속성으로 전달
- `updated`: 수정 시각

발행 후 수정하면 사이트 원문과 ActivityPub `Update`를 함께 갱신한다.

발행 장문을 삭제(discard)하면 ActivityPub `Delete`(Tombstone)를 발행해 연합된 인스턴스에서도 제거되게 한다. 이는 `Article`과 동일한 Federails + Discard 통합으로 처리한다: `after_discard`에서 `create_federails_activity "Delete"`를 호출하고, `acts_as_federails_data`에 `soft_deleted_method: :discarded?`, `soft_delete_date_method: :deleted_at`를 지정한다. `soft_deleted_method`가 설정되면 삭제된 레코드는 `federails_tombstoned?`가 참이 되어, `deleted_at` 갱신이 일으키는 일반 `Update` 활동은 자동으로 억제되고 `Delete`만 발행된다. 인바운드 연합 삭제 요청(`on_federails_delete_requested`)은 타입별로 분기한다: 장문은 `discard!`(소프트, 휴지통에 남김), 단문·댓글은 `destroy!`(hard, 레코드·카운터 제거). 초안은 발행된 적이 없으므로(로컬 미연합) 삭제 시 연합 활동이 발행되지 않는다.

휴지통에서 복원(undiscard)하면 발행이었던 글은 ActivityPub `Undo`로 원격에 되살린다(`after_undiscard`에서 발행 글에 한해 `create_federails_activity "Undo"`, 인바운드 `on_federails_undelete_requested`는 `undiscard!`). 휴지통에서 영구 삭제(hard `destroy`)하면 발행이었던 글은 Federails의 `after_destroy` 경로로 다시 `Delete`/Tombstone을 발행한다. 초안은 복원·영구삭제 모두 연합 활동을 발행하지 않는다.

요약은 별도 입력란 없이 본문 앞부분에서 자동 추출한다. HTML 태그와 과도한 공백을 제거하고, 링크와 원문 URL을 함께 제공한다.

## 컨트롤러와 라우팅

예상 라우팅은 다음 범위를 갖는다.

- 장문 초안 생성
- 장문 편집 화면 표시
- 자동 저장
- 발행
- 발행 후 수정
- 삭제(soft discard)

장문 전용 `LongformPostsController`에 `destroy` 액션을 추가하고, 표준 `DELETE` 요청을 받아 실제 레코드 삭제 대신 `@post.discard`(`Discard::Model`)를 호출한다. 연합 `Delete` 발행은 모델의 `after_discard` 콜백이 담당하므로 컨트롤러는 연합을 직접 다루지 않는다. 소유자 검증은 기존 `authorize_owner!`를 재사용한다.

구현 계획에서는 기존 `PostsController`에 액션을 추가할지, 장문 전용 컨트롤러를 둘지 결정한다. 첫 설계 기준은 일반 `Post` 생성과 장문 편집 책임이 섞이지 않도록 장문 전용 컨트롤러를 우선 검토한다.

## 테스트 전략

PostgreSQL 기준으로 검증한다.

- 모델 테스트
  - 장문 발행 시 제목 필수
  - 단문은 제목 없이 계속 유효
  - 댓글 흐름 회귀
  - 초안과 발행 상태 전환
- 컨트롤러 테스트
  - 인증 필요
  - 장문 초안 생성
  - 자동 저장
  - 발행
  - 발행 후 수정
  - 타인의 초안 접근 차단
  - 삭제 시 `status`가 `discarded`로 전환
  - 타인의 글 삭제 차단
  - 삭제 후 피드·프로필 목록에서 제외
- ActivityPub 테스트
  - 단문은 기존 전체 본문 발행 유지
  - 장문은 요약과 원문 URL 발행
  - 장문 수정 시 `Update` 발행
  - 발행 장문 삭제 시 `Delete`(Tombstone) 발행(또는 기존 Federails 메커니즘 동작 확인)
- 통합 테스트
  - 단문 작성창에서 `장문 쓰기` 진입
  - 제목과 본문 작성
  - 자동 저장 후 발행
  - 프로필 글 목록에서 발행 장문 확인
  - 초안 안내에서 초안을 다시 열어 수정
  - 발행 장문 삭제 후 목록에서 사라짐 확인

구현 완료 전에는 `bin/rails test`와 `bin/rake quality`를 PostgreSQL 기준으로 실행한다. 품질 게이트가 기존 기준선 문제로 실패하면 신규 변경과 기존 부채를 분리해 보고한다.

## 승인된 결정

- 완전한 블로그 모델이 아니라 기존 `Post` 확장에서 시작한다.
- `post_type`과 `status`는 Rails enum으로 모델에 선언한다.
- 장문에는 제목을 둔다.
- 제목은 장문 모드에서만 필수다.
- 기존 작성창의 `장문 쓰기` 버튼으로 전용 편집 화면에 진입한다.
- 초안 자동 저장과 명시적 발행 버튼을 지원한다.
- Lexxy 리치 텍스트 편집기를 사용한다.
- 본문 이미지는 업로드하지 않고 외부 이미지 URL 삽입만 지원한다.
- 발행 후 수정과 ActivityPub `Update`를 지원한다.
- 장문 ActivityPub 발행은 요약과 원문 링크 방식이다.
- 공개 프로필 글 목록은 발행 콘텐츠 노출용으로 유지하고, 장문 글쓰기 관리(초안·발행·휴지통)는 소유자 전용 `장문` 탭 한 곳에 모은다.
- 기존 초안과 발행 장문을 편집기로 다시 열어 수정할 수 있다. 수정 진입점은 `장문` 탭과 발행 장문 원문 페이지에 둔다.
- 소프트 삭제(휴지통/복원)는 장문 전용이다. 단문·댓글은 hard delete한다. 삭제는 `Discard::Model`(기존 `Article` 패턴)을 사용하고, `status` enum에는 별도 `discarded` 값을 두지 않는다(발행 상태와 삭제 상태는 직교).
- 발행 장문 삭제 시 `after_discard`에서 ActivityPub `Delete`(Tombstone)를 발행한다. `soft_deleted_method: :discarded?` 설정으로 삭제 시 불필요한 `Update` 활동은 억제된다.
- 공개 피드 쿼리도 `visible`로 제한해 초안·`discarded` 글이 노출되지 않게 한다.
- 삭제된 장문은 `장문` 탭의 휴지통 하위 구분에서 복원(undiscard)·영구삭제(hard destroy)할 수 있다. 복원 시 발행 글은 `Undo`, 영구삭제 시 발행 글은 `Delete`를 발행한다.
- 모든 공개 read 경로(원문 show, 기사 댓글, 프로필 댓글 탭, 홈 최근 댓글, 카운터)는 `kept`/`visible`를 강제해 discarded 글·댓글이 새지 않게 한다. 비공개 초안 원문은 소유자 본인만 미리 볼 수 있다.
- 수정 링크는 `data-turbo-prefetch="false"`로 hover prefetch를 끈다.
