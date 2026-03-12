# Future: Memo/Note Model (단문 메시지)

Article이 아닌 단문 메시지를 위한 새로운 모델 (Memo 또는 Note) 추가 계획.

## 고려사항
- ActivityPub Note 타입으로 federate
- `handle_federated_object?`에서 Article/Comment 외에 Memo/Note도 구분 필요
- 단순 멘션(@bot) 처리 시 이 모델로 연결 가능성 있음
- Comment의 `from_activitypub_object` 처럼 별도 파싱 로직 필요
- inReplyTo 없는 단순 멘션도 이 모델로 수신 처리 가능
