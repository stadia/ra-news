# frozen_string_literal: true

# 임베딩 모델 gemini-embedding-2(MRL 최대 3072d) 전환에 맞춰 컬럼을 halfvec(3072)로 변경.
# vector 타입은 HNSW 인덱스가 2000차원까지만 지원하므로, 4000차원까지 지원하는 halfvec를 쓴다.
# halfvec(3072)=6KB 로 기존 vector(1536)=6KB 와 저장 용량이 동일하다.
# 기존 벡터는 구 모델 공간 + 차원 불일치로 폐기하고, 배포 후 `rake articles:reembed`로 재생성한다.
class ChangeArticlesEmbeddingToHalfvec3072 < ActiveRecord::Migration[8.1]
  def up
    remove_index :articles, :embedding, if_exists: true

    execute "UPDATE articles SET embedding = NULL WHERE embedding IS NOT NULL"
    execute "ALTER TABLE articles ALTER COLUMN embedding TYPE halfvec(3072) USING NULL"

    # HNSW 병렬 빌드는 워커마다 /dev/shm에 큰 세그먼트를 할당해 shared memory 부족을
    # 일으킬 수 있어 단일 워커로 빌드한다.
    execute "SET max_parallel_maintenance_workers = 0"
    add_index :articles,
              :embedding,
              using: :hnsw,
              opclass: :halfvec_l2_ops,
              if_not_exists: true
  end

  def down
    remove_index :articles, :embedding, if_exists: true

    execute "UPDATE articles SET embedding = NULL WHERE embedding IS NOT NULL"
    execute "ALTER TABLE articles ALTER COLUMN embedding TYPE vector(1536) USING NULL"

    execute "SET max_parallel_maintenance_workers = 0"
    add_index :articles,
              :embedding,
              using: :hnsw,
              opclass: :vector_l2_ops,
              if_not_exists: true
  end
end
