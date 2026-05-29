class AddBigmIndexToPgSearchDocuments < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # 하이브리드 전문 검색용 bigram 인덱스.
  # 기존 tsvector_content_tsearch(textsearch_ko, 'korean')는 한국어 형태소에 강하지만
  # 일본어 가나(ひらがな/カタカナ)를 토큰화하지 못해 검색에서 누락된다.
  # pg_bigm은 언어 중립적 2-gram 색인이라 한/일/중 + 부분 일치를 모두 커버한다.
  # full_text_search_for 스코프에서 `content LIKE '%term%'`를 이 인덱스로 가속한다.
  # 주의: ILIKE는 gin_bigm_ops 인덱스를 타지 않으므로 쿼리는 반드시 LIKE를 사용한다.
  def up
    execute "CREATE EXTENSION IF NOT EXISTS pg_bigm;"
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_pg_search_documents_on_content_bigm
        ON pg_search_documents USING gin (content gin_bigm_ops)
    SQL
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_pg_search_documents_on_content_bigm"
  end
end
