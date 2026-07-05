# Article 제출자 기본 좋아요 설계

## 목표

인증된 사용자가 일반 Article 등록 폼을 제출해 새 Article이 저장되면, 제출한 `current_user`의 Like를 기본으로 함께 생성한다.

## 범위

- 대상은 `ArticlesController#create`를 통한 일반 웹 폼 등록이다.
- Article의 `user`는 기존 동작대로 `User.first_bot`을 유지한다.
- API 및 관리자 Article 생성 흐름은 변경하지 않는다.
- 기존 Article 중복 처리, 검증 오류 응답, `ArticleJob` enqueue 동작은 유지한다.

## 설계

Article 저장과 `current_user.like!(@article)` 호출을 하나의 데이터베이스 트랜잭션으로 묶는다. 둘 중 하나라도 실패하면 Article과 Like가 함께 롤백되어, 성공 응답을 받은 Article에는 항상 제출자의 Like가 존재하도록 한다. Like 생성에는 기존 `User#like!` 도메인 메서드를 재사용하여 actor 해석, 중복 방지, 카운터 및 ActivityPub 콜백 동작을 보존한다.

트랜잭션이 성공한 뒤 기존처럼 `ArticleJob`을 enqueue하고 Article 상세 화면으로 이동한다. Article 검증이 실패하면 Like를 만들지 않고 기존 오류 화면을 렌더링한다.

## 검증

컨트롤러 통합 테스트에서 인증 사용자가 유효한 URL을 제출했을 때 다음을 검증한다.

- 새 Article이 생성된다.
- Article 소유자는 `User.first_bot`이다.
- 제출자의 federails actor를 가진 Like가 생성된다.
- Article의 `likers_count`가 갱신된다.

기존 빈 URL 테스트로 저장 실패 시 Like가 생기지 않는 흐름을 계속 보호한다.

