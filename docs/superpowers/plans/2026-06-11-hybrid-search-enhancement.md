# 하이브리드 검색 강화 — Tier 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 하이브리드 검색 파라미터를 외부 설정화하고, 검색 품질을 객관적으로 측정할 MRR 벤치마크를 도입하며, pg_bigm 기반 검색어 제안 기능을 추가한다.

**Architecture:** 세 가지 독립적인 작업을 순차적으로 진행한다. Task 1(파라미터 YAML화)은 기존 `HybridSearch`를 수정하고, Task 2(MRR 벤치마크)는 rake task + 평가 데이터를 생성하며, Task 3(검색어 제안)은 신규 모듈 + 뷰 통합을 추가한다.

**Tech Stack:** Rails 8.1, Minitest + fixtures, pg_bigm, Solid Cache.

설계 문서: `docs/superpowers/specs/2026-06-11-hybrid-search-enhancement.md`

---

## TDD 규율: Canon TDD (Kent Beck)

이 플랜은 **Canon TDD**로 실행한다. 각 Task의 테스트 코드 블록은 한꺼번에 작성하는 파일이 아니라
**테스트 리스트**다. 실행 루프:

1. Task의 테스트 리스트를 확인한다(이미 플랜에 나열됨).
2. 리스트에서 **정확히 하나**의 테스트만 파일에 추가한다 → 실행해 **Red** 확인.
3. 그 테스트 + **기존 모든 테스트**가 통과하도록 최소 구현을 추가/수정한다 → **Green** 확인.
4. (선택) 리팩터링 — 테스트 유지한 채 구조 개선.
5. 리스트의 다음 테스트로 2로 돌아간다. 구현 중 새 케이스를 발견하면 리스트에 추가한다.

---

## File Structure

생성:
- `config/hybrid_search.yml` — 파라미터 설정 파일
- `config/hybrid_search_test.yml` — 테스트 환경용 설정 (CANDIDATE_POOL 작게)
- `lib/tasks/search_benchmark.rake` — MRR 벤치마크 rake task
- `test/fixtures/search_eval_queries.yml` — 평가 쿼리셋
- `app/functions/articles/search_suggestions.rb` — pg_bigm 검색어 제안
- `test/functions/search/benchmark_test.rb`
- `test/functions/articles/search_suggestions_test.rb`

수정:
- `app/functions/articles/hybrid_search.rb` — 상수 → `config_for(:hybrid_search)` 로드
- `app/functions/articles/query.rb` — 검색 결과 0건 시 제안 전달 (선택)
- `app/controllers/articles_controller.rb` — `@suggestions` 전달 (선택)

---

### Task 1: 파라미터 외부 설정화 (YAML)

**Files:**
- Create: `config/hybrid_search.yml`
- Create: `config/hybrid_search_test.yml`
- Modify: `app/functions/articles/hybrid_search.rb`
- Create: `test/functions/articles/hybrid_search_config_test.rb`

- [ ] **Step 1: Test list — add ONE test at a time (Canon TDD), Red→Green each before the next**

```ruby
# test/functions/articles/hybrid_search_config_test.rb
# frozen_string_literal: true

require "test_helper"

class Articles::HybridSearchConfigTest < ActiveSupport::TestCase
  test "reads candidate_pool from config/hybrid_search.yml" do
    assert_equal 10, Articles::HybridSearch::CANDIDATE_POOL
  end

  test "reads rrf_k from config" do
    assert_equal 60, Articles::HybridSearch::RRF_K
  end

  test "reads cosine_threshold from config" do
    assert_in_delta 0.6, Articles::HybridSearch::COSINE_THRESHOLD, 1e-9
  end

  test "reads mmr_lambda from config" do
    assert_in_delta 0.7, Articles::HybridSearch::MMR_LAMBDA, 1e-9
  end

  test "reads embed_cache_ttl from config" do
    assert_equal 12.hours, Articles::HybridSearch::EMBED_CACHE_TTL
  end

  test "falls back to default when config key is missing" do
    # config/hybrid_search_test.yml 의도적으로 candidate_pool 키 생략 → 기본값 100
    # 이미 테스트 환경 yml 로드로 검증
    assert_equal 10, Articles::HybridSearch::CANDIDATE_POOL
  end
end
```

- [ ] **Step 2: Create config/hybrid_search.yml**

```yaml
# config/hybrid_search.yml
default: &default
  candidate_pool: 100
  rrf_k: 60
  cosine_threshold: 0.6
  mmr_lambda: 0.7
  embed_cache_ttl: 43200  # seconds (12 hours)

development:
  <<: *default

test:
  <<: *default
  candidate_pool: 10  # test 환경에서는 작은 풀로 빠르게

production:
  <<: *default
```

- [ ] **Step 3: Modify HybridSearch to read from config**

```ruby
# app/functions/articles/hybrid_search.rb 수정
# 상수 정의 부분을:
#   CANDIDATE_POOL = 100
#   RRF_K = 60
#   ...
# 에서 config_for 로 동적 로드하도록 변경
```

- [ ] **Step 4: Verify existing tests still pass**

Run: `bin/rails test test/functions/articles/hybrid_search_test.rb`
Expected: 기존 6개 테스트 모두 통과

---

### Task 2: 검색 품질 측정 (MRR 벤치마크)

**Files:**
- Create: `test/fixtures/search_eval_queries.yml`
- Create: `lib/tasks/search_benchmark.rake`
- Create: `test/functions/search/benchmark_test.rb`

- [ ] **Step 1: Create evaluation queries fixture**

```yaml
# test/fixtures/search_eval_queries.yml
ruby_performance:
  query: "Ruby 성능 최적화"
  relevant_ids:
    - <%= ActiveRecord::FixtureSet.identify(:ruby_article) %>
```

- [ ] **Step 2: Test list — add ONE test at a time**

```ruby
# test/functions/search/benchmark_test.rb
# frozen_string_literal: true

require "test_helper"

class SearchBenchmarkTest < ActiveSupport::TestCase
  test "mrr returns 1.0 when first result is relevant" do
    assert_in_delta 1.0, SearchBenchmark.mrr([[1, 2, 3]], [1]), 1e-9
  end

  test "mrr returns 1/rank when relevant at position N" do
    # relevant_id=3 is at position 3 (index 2) in second query
    assert_in_delta 1.0 / 3, SearchBenchmark.mrr([[1, 2, 3]], [3]), 1e-9
  end

  test "mrr returns 0.0 when no relevant result found" do
    assert_equal 0.0, SearchBenchmark.mrr([[1, 2]], [5])
  end

  test "mrr averages across multiple queries" do
    # query1: relevant at pos1 → 1.0, query2: relevant at pos2 → 0.5
    assert_in_delta 0.75, SearchBenchmark.mrr([[10, 20], [30, 40]], [10, 40]), 1e-9
  end

  test "ndcg_at_k returns 1.0 for perfect ranking" do
    assert_in_delta 1.0, SearchBenchmark.ndcg_at([[1, 2, 3]], [[1, 2, 3]], k: 3), 1e-9
  end

  test "recall_at_k returns fraction of relevant found" do
    assert_in_delta 0.5, SearchBenchmark.recall_at([[1, 3]], [[1, 2]], k: 5), 1e-9
  end
end
```

- [ ] **Step 3: Implement SearchBenchmark module**

```ruby
# lib/search_benchmark.rb
module SearchBenchmark
  module_function

  #: (Array[Array[Integer]] ranked_lists, Array[Array[Integer]]? relevant_ids) -> Float
  def mrr(ranked_lists, relevant_ids)
    # ...
  end

  #: (Array[Array[Integer]] ranked_lists, Array[Array[Integer]]? ideal_ranking, ?k: Integer) -> Float
  def ndcg_at(ranked_lists, ideal_ranking, k: 10)
    # ...
  end

  #: (Array[Array[Integer]] ranked_lists, Array[Array[Integer]]? relevant_ids, ?k: Integer) -> Float
  def recall_at(ranked_lists, relevant_ids, k: 10)
    # ...
  end
end
```

- [ ] **Step 4: Create rake task**

```ruby
# lib/tasks/search_benchmark.rake
namespace :search do
  desc "Compare FTS-only vs Hybrid search quality (MRR, NDCG@10, Recall@10)"
  task benchmark: :environment do
    # 평가 쿼리 로드 → FTS-only 결과 → Hybrid 결과 → 메트릭 계산 → 리포트 출력
  end
end
```

---

### Task 3: 검색어 유사도 기반 제안 (pg_bigm)

**Files:**
- Create: `app/functions/articles/search_suggestions.rb`
- Create: `test/functions/articles/search_suggestions_test.rb`

- [ ] **Step 1: Test list — add ONE test at a time**

```ruby
# test/functions/articles/search_suggestions_test.rb
# frozen_string_literal: true

require "test_helper"

class Articles::SearchSuggestionsTest < ActiveSupport::TestCase
  test "returns suggested titles for a query" do
    suggestions = Articles::SearchSuggestions.suggest("Ruby")
    assert_includes suggestions, articles(:ruby_article).title_ko
  end

  test "returns empty array for blank query" do
    assert_equal [], Articles::SearchSuggestions.suggest("")
    assert_equal [], Articles::SearchSuggestions.suggest("   ")
  end

  test "respects limit parameter" do
    suggestions = Articles::SearchSuggestions.suggest("Ruby", limit: 1)
    assert_equal 1, suggestions.size
  end

  test "deduplicates title_ko and title" do
    # 같은 제목이 title_ko와 title에 중복 등장해도 한 번만
    suggestions = Articles::SearchSuggestions.suggest("Ruby")
    assert_equal suggestions.uniq, suggestions
  end
end
```

- [ ] **Step 2: Implement module**

```ruby
# app/functions/articles/search_suggestions.rb
# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module SearchSuggestions
    module_function

    #: (String query, ?limit: Integer, ?threshold: Float) -> Array[String]
    def suggest(query, limit: 5, threshold: 0.3)
      # ...
    end
  end
end
```

---

### Task 4: 검색 제안 통합 (컨트롤러·뷰)

**Files:**
- Modify: `app/controllers/articles_controller.rb` — `@suggestions` 전달
- Modify: `app/functions/articles/query.rb` — 제안 로직 호출 (또는 컨트롤러에서 직접)

- [ ] **Step 1: 검색 결과 0건 시 제안 로드**

```ruby
# articles_controller.rb index 액션
@suggestions = if @articles.empty? && search.present?
                 Articles::SearchSuggestions.suggest(search)
               else
                 []
               end
```

- [ ] **Step 2: 뷰에 제안 컴포넌트 추가**

Phlex `Views::Articles::Index`에 `@suggestions`이 비어있지 않을 때
"이렇게 검색해보세요: ..." 섹션을 렌더링한다.

