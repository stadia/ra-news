# frozen_string_literal: true

require "test_helper"

class HybridSearchServiceTest < ActiveSupport::TestCase
  # RubyLLM.embed 응답을 흉내내는 Struct (vectors.to_a 인터페이스)
  EmbedResult = Struct.new(:vectors)

  def setup
    Rails.cache.clear
  end

  # --- Phase 1: 입력 검증 / 임베딩 실패 ---

  test "빈 쿼리는 Failure(:blank_query)" do
    result = HybridSearchService.new.call("")

    assert_predicate result, :failure?
    assert_equal :blank_query, result.failure
  end

  test "nil 쿼리는 Failure(:blank_query)" do
    result = HybridSearchService.new.call(nil)

    assert_predicate result, :failure?
    assert_equal :blank_query, result.failure
  end

  test "RubyLLM.embed 예외 시 Failure(:embedding_failed)" do
    RubyLLM.stub(:embed, ->(*) { raise StandardError, "API down" }) do
      result = HybridSearchService.new.call("ruby performance")

      assert_predicate result, :failure?
      assert_equal :embedding_failed, result.failure
    end
  end

  test "임베딩이 빈 벡터면 Failure(:embedding_failed)" do
    RubyLLM.stub(:embed, ->(*, **) { EmbedResult.new([]) }) do
      result = HybridSearchService.new.call("ruby performance")

      assert_predicate result, :failure?
      assert_equal :embedding_failed, result.failure
    end
  end

  test "임베딩 결과는 캐시된다 — 동일 쿼리는 RubyLLM.embed를 한 번만 호출" do
    call_count = 0
    embedder = lambda do |*, **|
      call_count += 1
      EmbedResult.new([1.0, 0.0, 0.0])
    end

    # 테스트 환경은 :null_store라 캐싱 검증을 위해 메모리 스토어로 임시 교체
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    RubyLLM.stub(:embed, embedder) do
      service = HybridSearchService.new
      # 후속 phase를 short-circuit 하기 위해 fulltext/vector를 빈 결과로 stub
      service.stub(:fulltext_candidates, ->(_) { Dry::Monads::Success([]) }) do
        service.stub(:vector_candidates, ->(_) { Dry::Monads::Success({ ranked_ids: [], similarities: {} }) }) do
          service.call("같은 쿼리")
          service.call("같은 쿼리")
        end
      end
    end

    assert_equal 1, call_count
  ensure
    Rails.cache = original_cache if defined?(original_cache) && original_cache
  end

  # --- Phase 5: threshold 필터 (protected 메서드 직접 검증) ---

  test "threshold 필터는 벡터 후보 중 임계값 미만 id를 제거한다" do
    service = HybridSearchService.new
    similarities = { 1 => 0.9, 2 => 0.3, 3 => 0.6 }
    result = service.send(:apply_threshold, [1, 2, 3], similarities)

    assert_predicate result, :success?
    assert_equal [1, 3], result.value!
  end

  test "threshold 필터는 벡터 후보에 없는 id(similarity 미상)를 통과시킨다" do
    service = HybridSearchService.new
    # id=99는 전문검색에만 잡혀 similarity 정보 없음 → 통과
    similarities = { 1 => 0.9, 2 => 0.2 }
    result = service.send(:apply_threshold, [1, 2, 99], similarities)

    assert_predicate result, :success?
    assert_equal [1, 99], result.value!
  end

  # --- Phase 4: RRF 통합 (서비스 경유) ---

  test "fuse는 후보가 없으면 Failure(:no_candidates)" do
    service = HybridSearchService.new
    result = service.send(:fuse, [], [])

    assert_predicate result, :failure?
    assert_equal :no_candidates, result.failure
  end

  test "fuse는 두 순위 리스트를 RRF로 병합한다" do
    service = HybridSearchService.new
    result = service.send(:fuse, [1, 2], [2, 3])

    assert_predicate result, :success?
    # id=2는 양쪽 등장 → 최상위
    assert_equal 2, result.value!.first
    assert_equal [1, 2, 3].sort, result.value!.sort
  end

  # --- Phase 6: rerank (빈 후보 경로) ---

  test "rerank는 후보 id가 없으면 빈 배열을 반환한다" do
    service = HybridSearchService.new
    result = service.send(:rerank, [1.0, 0.0], [], 10)

    assert_predicate result, :success?
    assert_empty result.value!
  end

  # --- 상수 노출 ---

  test "튜닝 파라미터는 상수로 노출된다" do
    assert_equal 60, HybridSearchService::RRF_K
    assert_equal 0.5, HybridSearchService::MMR_LAMBDA
    assert_equal 30, HybridSearchService::VECTOR_CANDIDATES
    assert_equal 30, HybridSearchService::FULLTEXT_CANDIDATES
    assert_equal 0.5, HybridSearchService::SIMILARITY_THRESHOLD
    assert_equal 10, HybridSearchService::RESULT_LIMIT
  end
end
