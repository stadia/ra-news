# frozen_string_literal: true

# HNSW 인덱스 opclass 를 halfvec_l2_ops → halfvec_cosine_ops 로 교체.
# 앱의 의미 기준이 코사인(COSINE_THRESHOLD + MMR cosine rerank)이므로 후보 검색도 코사인으로 일치시킨다.
# 인덱스와 쿼리(distance: "cosine")를 둘 다 코사인으로 맞추면 인덱스를 그대로 탄다.
# 임베딩 정규화 여부와 무관하게 검색~필터~재랭킹 단계가 동일 기준으로 동작한다.
class SwitchArticlesEmbeddingIndexToCosine < ActiveRecord::Migration[8.1]
  def up
    remove_index :articles, :embedding, if_exists: true

    # HNSW 병렬 빌드는 워커마다 /dev/shm에 큰 세그먼트를 할당해 shared memory 부족을
    # 일으킬 수 있어 단일 워커로 빌드한다.
    execute "SET max_parallel_maintenance_workers = 0"
    add_index :articles,
              :embedding,
              using: :hnsw,
              opclass: :halfvec_cosine_ops,
              if_not_exists: true
  end

  def down
    remove_index :articles, :embedding, if_exists: true

    execute "SET max_parallel_maintenance_workers = 0"
    add_index :articles,
              :embedding,
              using: :hnsw,
              opclass: :halfvec_l2_ops,
              if_not_exists: true
  end
end
