# frozen_string_literal: true

class AddHnswIndexToArticlesEmbedding < ActiveRecord::Migration[8.1]
  def up
    # HNSW 병렬 빌드는 워커마다 /dev/shm에 큰 세그먼트를 할당해
    # shared memory 부족(PG::DiskFull)을 일으킬 수 있어 단일 워커로 빌드한다.
    execute "SET max_parallel_maintenance_workers = 0"

    add_index :articles,
              :embedding,
              using: :hnsw,
              opclass: :vector_l2_ops,
              if_not_exists: true
  end

  def down
    remove_index :articles, :embedding, if_exists: true
  end
end
