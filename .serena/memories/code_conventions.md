# 코드 컨벤션

## Type Annotations (RBS Inline)
```ruby
# rbs_inline: enabled

def process_content(url) #: (String) -> void
```

## Soft Delete
```ruby
include Discard::Model
Article.kept.find_by_slug(params[:id])  # kept scope 사용
```

## Service Layer Pattern

### ApplicationService (단순 비즈니스 로직)
- 예시: SitemapService

### Dry::Operation (다단계 워크플로우, 명시적 에러 처리)
```ruby
class ContentService < Dry::Operation
  def call(article)
    step validate(article)
    step process(article)
  end
end

result = ContentService.new.call(article)
result.success? ? result.value! : result.failure
```

## Error Handling
- ApplicationJob: StandardError rescue + Honeybadger 보고
- Client 클래스: 표준화된 에러 타입 (Forbidden, RateLimit, NotFound)
- 컨트롤러: render turbo_stream: 또는 명시적 status 코드

## Search System
```ruby
# 전문 검색 (한국어 사전 + tsvector)
Article.full_text_search_for(term)

# 언어별 검색
Article.title_matching(query)  # Korean dictionary
Article.body_matching(query)     # English dictionary

# 벡터 유사도
article.nearest_neighbors(:embedding, distance: "cosine")
```

## 기타 규칙
- 모든 응답은 한국어로 작성
- 변경 전후 맥락과 테스트 결과를 커밋 메시지에 기록
