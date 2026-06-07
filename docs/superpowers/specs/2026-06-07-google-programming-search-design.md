# Google 프로그래밍 검색 보조 탭 설계

## 목적

기존 PostgreSQL 기반 Ruby-News 기사 검색을 기본 검색으로 유지하면서,
Google Programmable Search Engine(CSE)을 보조 검색 수단으로 제공한다.
두 검색 수단은 동일한 검색 결과 화면의 탭으로 구분하고 검색어를 공유한다.

## 사용자 흐름

1. 사용자가 기존 검색창에서 검색어를 입력한다.
2. `/articles?search=<검색어>`에서 Ruby-News 검색 결과가 기본 탭으로 표시된다.
3. 사용자가 `Google 프로그래밍 검색` 탭을 선택한다.
4. 브라우저는 `/articles?search=<검색어>&source=google`로 이동한다.
5. Google CSE 스크립트가 이 화면에서만 로드되고 기존 검색어로 검색을 실행한다.
6. 새로고침, 뒤로 가기, 링크 공유 후에도 URL의 `source` 값에 따라 탭이 유지된다.

## URL 계약

- Ruby-News 탭: `/articles?search=ruby`
- Google 탭: `/articles?search=ruby&source=google`
- `source`가 없거나 `google` 이외의 값이면 Ruby-News 탭으로 처리한다.
- 기존 `search` 정규화 규칙과 최대 길이 제한을 Google 탭에도 동일하게 적용한다.
- 빈 검색어로 Google 탭에 진입할 수 있으며, 이 경우 Google CSE의 빈 검색 화면을 표시한다.

## 렌더링 구조

`ArticlesController#index`는 정규화된 검색어와 선택된 검색 소스를
`Views::Articles::Index`에 전달한다.

뷰는 검색 결과 제목 아래에 링크 기반 탭 두 개를 렌더링한다.

- `Ruby-News`: 현재 검색어를 유지하고 `source`를 제거한 URL
- `Google 프로그래밍 검색`: 현재 검색어와 `source=google`을 포함한 URL

선택된 탭은 시맨틱 상태와 시각적 강조를 함께 제공한다. 탭은 링크로 구현해
JavaScript가 없어도 이동, 뒤로 가기, 새로고침이 동작하게 한다. 스타일은
`DESIGN.md`의 시맨틱 토큰과 Tailwind v4 규칙을 따른다.

Ruby-News 탭에서는 기존 기사 목록, 태그 사이드바, 페이지네이션을 변경하지 않는다.
Google 탭에서는 해당 목록 대신 Google CSE 영역을 표시한다.

## Google CSE 연동

Google 탭일 때만 다음 외부 스크립트를 비동기로 로드한다.

```text
https://cse.google.com/cse.js?cx=119e8b7b7b2f64488
```

페이지에는 Google CSE 검색 컨테이너를 렌더링한다. 기존 `search` 값을 초기 검색어로
전달하고 검색을 자동 실행한다. 구체적인 초기화는 Google CSE가 제공하는 공식
element callback/API를 사용하며, 구현 전에 현재 API 동작을 공식 문서로 검증한다.

Turbo 페이지 이동과 캐시 복원에서도 스크립트가 중복 삽입되거나 초기화가 여러 번
실행되지 않도록 이미 로드된 스크립트와 element 상태를 확인한다.

## 오류와 개인정보 경계

- 기본 Ruby-News 탭에서는 Google 스크립트나 Google CSE DOM을 렌더링하지 않는다.
- Google 탭 진입은 외부 Google 리소스 요청이 발생하는 명시적 사용자 동작이다.
- 스크립트 로딩 또는 초기화 실패 시 검색 영역에 한국어 오류 안내를 표시한다.
- 오류가 나도 Ruby-News 탭 링크는 계속 사용할 수 있어야 한다.
- 새 번역 키는 `config/locales/ko.yml`에 우선 추가하고 영어·일본어 번역도 맞춘다.

## 테스트

컨트롤러 또는 요청 테스트에서 다음을 검증한다.

- 기본 요청은 Ruby-News 탭을 선택한다.
- `source=google` 요청은 Google 탭을 선택한다.
- 알 수 없는 `source` 값은 기본 탭으로 정규화된다.
- 기존 검색어 정규화와 길이 제한이 유지된다.

Phlex 뷰 테스트에서 다음을 검증한다.

- 두 탭 링크가 현재 검색어를 올바르게 보존한다.
- 선택된 탭에 접근 가능한 현재 상태가 표시된다.
- 기본 탭에는 Google CSE 스크립트가 없다.
- Google 탭에만 CSE 컨테이너와 지정된 `cx` 스크립트가 있다.
- Google 탭에서 기존 기사 목록과 페이지네이션이 중복 표시되지 않는다.
- 스크립트 실패 안내에 한국어 문구와 Ruby-News 탭 복귀 경로가 있다.

구현 후 PostgreSQL 기준 관련 테스트, 전체 검증이 필요하면 전체 테스트,
`bin/rake quality`를 실행하고 네 개 품질 게이트 수치를 보고한다.

## 제외 범위

- 기존 PostgreSQL 전문 검색 알고리즘 변경
- Google 검색 결과의 서버 저장 또는 재가공
- Google 검색 결과와 Ruby-News 결과의 혼합 정렬
- 별도 Google 검색 전용 라우트
- 관리 화면에서 CSE ID를 변경하는 설정 기능
