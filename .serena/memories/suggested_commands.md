# 주요 개발 명령어

## 개발 서버
```bash
bin/dev                    # Rails + CSS watcher
```

## 테스트
```bash
bin/rails test                                 # 전체 테스트
bin/rails test test/models/article_test.rb     # 단일 파일
bin/rails test:system BROWSER=headless_firefox # 시스템 테스트
```

**중요:** 테스트 환경은 PostgreSQL 사용 (SQLite 아님)
- 이유: pgvector, textsearch_ko, pg_bigm 등 production과 동일한 확장 필요
- 설정: TEST_DATABASE_URL 환경 변수 우선

## 코드 품질
```bash
bin/rubocop --autocorrect-all   # 린트 검사 및 자동 수정
bundle exec steep check         # 타입 검사
bin/brakeman                    # 보안 스캔
```

## 백그라운드 작업
```bash
bin/jobs  # 백그라운드 워커
```

## GitHub PR 작업
```bash
gh pr view --comments  # PR 코멘트 가져오기
```

## 유틸리티
```bash
git log --oneline -20  # 최근 커밋
bundle install         # 의존성 설치
yarn install           # JS 의존성 설치
```

## CI 파이프라인
- scan_ruby: Brakeman + bundler-audit
- scan_js: importmap audit
- lint: RuboCop
- test: 전체 테스트 (PostgreSQL)
