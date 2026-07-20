# frozen_string_literal: true

require "test_helper"

class Articles::SearchTest < ActiveSupport::TestCase
  # ── cosine_similarity ──────────────────────────────────────────

  test "identical vectors have similarity 1.0" do
    assert_in_delta 1.0, Articles::Search.cosine_similarity([ 1.0, 2.0, 3.0 ], [ 1.0, 2.0, 3.0 ]), 1e-9
  end

  test "orthogonal vectors have similarity 0.0" do
    assert_in_delta 0.0, Articles::Search.cosine_similarity([ 1.0, 0.0 ], [ 0.0, 1.0 ]), 1e-9
  end

  test "opposite vectors have similarity -1.0" do
    assert_in_delta(-1.0, Articles::Search.cosine_similarity([ 1.0, 0.0 ], [ -1.0, 0.0 ]), 1e-9)
  end

  test "zero vector yields 0.0 without raising" do
    assert_in_delta(0.0, Articles::Search.cosine_similarity([ 0.0, 0.0 ], [ 1.0, 2.0 ]))
  end

  test "nil or empty input yields 0.0" do
    assert_in_delta(0.0, Articles::Search.cosine_similarity(nil, [ 1.0 ]))
    assert_in_delta(0.0, Articles::Search.cosine_similarity([], []))
  end

  test "size mismatch yields 0.0" do
    assert_in_delta(0.0, Articles::Search.cosine_similarity([ 1.0, 2.0 ], [ 1.0 ]))
  end

  # ── fuse ───────────────────────────────────────────────────────

  test "single list preserves order" do
    assert_equal [ 10, 20, 30 ], Articles::Search.fuse([ [ 10, 20, 30 ] ])
  end

  test "id appearing high in both lists ranks first" do
    list_a = [ 2, 1, 3 ]
    list_b = [ 2, 3, 1 ]
    # id 2 is rank-0 in both lists -> highest RRF score -> first
    assert_equal 2, Articles::Search.fuse([ list_a, list_b ]).first
  end

  test "deduplicates ids across lists" do
    result = Articles::Search.fuse([ [ 1, 2 ], [ 2, 1 ] ])

    assert_equal [ 1, 2 ].sort, result.sort
    assert_equal 2, result.size
  end

  test "ignores empty lists" do
    assert_equal [ 5, 6 ], Articles::Search.fuse([ [ 5, 6 ], [] ])
  end

  test "returns empty for no input" do
    assert_equal [], Articles::Search.fuse([])
    assert_equal [], Articles::Search.fuse([ [], [] ])
  end

  test "k parameter changes weighting toward larger k flattening" do
    result = Articles::Search.fuse([ [ 1, 2 ], [ 2, 3 ] ], k: 1_000_000)

    assert_includes result, 1
    assert_includes result, 2
    assert_includes result, 3
  end

  # ── rerank ─────────────────────────────────────────────────────

  # query ~ [1,0]. Candidates: a,b nearly identical (high relevance, low diversity),
  # c orthogonal (lower relevance, high diversity).
  def candidates
    [
      { id: :a, vector: [ 1.0, 0.0 ] },
      { id: :b, vector: [ 0.99, 0.01 ] },
      { id: :c, vector: [ 0.0, 1.0 ] }
    ]
  end

  test "first pick is the most relevant to the query" do
    result = Articles::Search.rerank(
      query_vector: [ 1.0, 0.0 ], candidates: candidates, lambda: 0.7, limit: 3
    )

    assert_equal :a, result.first
  end

  test "diversity beats a near-duplicate for the second slot" do
    # With lambda 0.5, after picking :a, :c (diverse) should beat :b (near-dup of :a)
    result = Articles::Search.rerank(
      query_vector: [ 1.0, 0.0 ], candidates: candidates, lambda: 0.5, limit: 2
    )

    assert_equal [ :a, :c ], result
  end

  test "returns all candidates when limit exceeds candidate count" do
    result = Articles::Search.rerank(
      query_vector: [ 1.0, 0.0 ], candidates: candidates, lambda: 0.7, limit: 10
    )

    assert_equal 3, result.size
    assert_equal [ :a, :b, :c ].sort, result.sort
  end

  test "empty candidates returns empty" do
    assert_equal [], Articles::Search.rerank(
      query_vector: [ 1.0, 0.0 ], candidates: [], lambda: 0.7, limit: 5
    )
  end

  # ── index_html ──────────────────────────────────────────────────
  # index_html은 pagy callable을 투명하게 호출해 결과를 그대로 전달만 하므로,
  # 실제 Pagy 인스턴스(Pagy 9 생성자 호환성 부담) 대신 sentinel 객체로 검증한다.

  test "index_html returns an IndexResult with empty suggestions when search is nil" do
    pagy = Object.new
    result = Articles::Search.index_html(search: nil, pagy: ->(_relation) { [ pagy, [] ] })

    assert_instance_of Articles::Search::IndexResult, result
    assert_equal pagy, result.pagy
    assert_equal [], result.articles
    assert_equal [], result.suggestions
  end

  test "index_html fills suggestions from suggest when articles empty and search present" do
    pagy = Object.new
    suggest_calls = []
    Articles::Search.stub(:suggest, ->(query, **) {
      suggest_calls << query
      [ "루비", "ruby on rails" ]
    }) do
      result = Articles::Search.index_html(search: "루비", pagy: ->(_relation) { [ pagy, [] ] })

      assert_equal [ "루비" ], suggest_calls
      assert_equal [ "루비", "ruby on rails" ], result.suggestions
      assert_equal [], result.articles
    end
  end

  test "index_html skips suggest when articles present" do
    pagy = Object.new
    article = articles(:ruby_article)
    suggest_calls = []
    Articles::Search.stub(:suggest, ->(*) {
      suggest_calls << :called
      []
    }) do
      result = Articles::Search.index_html(search: "ruby", pagy: ->(_relation) { [ pagy, [ article ] ] })

      assert_equal [], suggest_calls
      assert_equal [], result.suggestions
      assert_equal [ article ], result.articles
    end
  end

  # ── suggest ─────────────────────────────────────────────────────

  test "suggest returns empty array for blank query" do
    assert_equal [], Articles::Search.suggest("")
    assert_equal [], Articles::Search.suggest("   ")
    assert_equal [], Articles::Search.suggest(nil)
  end

  test "suggest returns array of strings" do
    result = Articles::Search.suggest("Ruby")

    assert_kind_of Array, result
  end

  test "suggest respects limit parameter by returning at most limit results" do
    result = Articles::Search.suggest("Ruby", limit: 2)

    assert_operator result.size, :<=, 2
  end

  test "suggest returns unique titles without duplicates" do
    result = Articles::Search.suggest("Ruby")

    assert_equal result.uniq, result
  end
end
