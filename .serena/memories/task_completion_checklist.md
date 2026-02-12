# 작업 완료 체크리스트

## 작업 완료 시 필수 확인 사항

### 1. 테스트
- [ ] 관련 테스트 파일 실행: `bin/rails test <test_file>`
- [ ] 전체 테스트 실행: `bin/rails test`
- [ ] 테스트 통과 확인

### 2. 코드 품질
- [ ] RuboCop 실행: `bin/rubocop --autocorrect-all`
- [ ] 타입 체크: `bundle exec steep check`
- [ ] 보안 스캔: `bin/brakeman`

### 3. 커밋
- [ ] 의미 있는 커밋 메시지 작성
- [ ] 변경 사항 요약 (파일:라인)
- [ ] 테스트 결과 기록

### 커밋 메시지 템플릿
```
[타입] 간결한 제목 (50자 이내)

- 변경 사항 1 (파일:라인)
- 변경 사항 2 (파일:라인)
- 테스트 결과: bin/rails test 통과

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 타입 분류
- feat: 새로운 기능 추가
- fix: 버그 수정
- refactor: 동작 변경 없는 리팩토링
- style: UI/레이아웃 변경
- test: 테스트 추가/수정
- docs: 문서 변경
