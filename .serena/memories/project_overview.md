# AL-News 프로젝트 개요

## 목적
뉴스 수집, AI 요약, 소셜 미디어 자동 게시 플랫폼

## 핵심 기능
- RSS/YouTube/Gmail/Hacker News에서 콘텐츠 수집
- AI(Gemini) 기반 한국어 요약 및 임베딩 생성
- X.com/Mastodon 자동 포스팅
- 전문 검색 (한국어 지원) 및 벡터 유사도 검색

## 핵심 모델
- Article: 콘텐츠 (AI 요약, embedding, soft-delete)
- Site: 소스 (RSS/YouTube/Gmail/HN)
- User: 인증 (Custom auth, Current.user 패턴)
- Comment: 댓글 (awesome_nested_set)

## 백그라운드 잡 (Solid Queue)
- ArticleJob: AI 요약/임베딩 생성
- RssSiteJob: RSS 피드 크롤링
- YoutubeSiteJob: YouTube 자막 추출
- GmailArticleJob: 이메일 뉴스레터 처리
- SocialPostJob: 소셜 미디어 자동 게시
- SocialDeleteJob: 소프트 삭제 시 소셜 포스트 삭제
