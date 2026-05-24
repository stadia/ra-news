class AddIndexesForTaggedArticlesQuery < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # tags: LOWER(name) ILIKE 쿼리를 위한 expression index
    # acts_as_taggable_on의 tagged_with가 LOWER(tags.name) ILIKE를 생성하므로
    # 일반 B-tree 인덱스는 사용되지 않음
    execute <<~SQL
      CREATE INDEX CONCURRENTLY index_tags_on_lower_name
        ON tags (LOWER(name))
    SQL

    # taggings: articles → taggings JOIN을 위한 복합 인덱스
    # 기존 taggings_idx는 [tag_id, ...]로 시작하여 taggable_id 조회에 부적합
    # 2025-10-24에 삭제된 [taggable_id, taggable_type, context] 인덱스를
    # tag_id까지 포함하여 복원
    add_index :taggings,
              [ :taggable_id, :taggable_type, :context, :tag_id ],
              name: "index_taggings_on_taggable_and_context_and_tag_id"
  end

  def down
    remove_index :taggings, name: "index_taggings_on_taggable_and_context_and_tag_id"
    execute "DROP INDEX IF EXISTS index_tags_on_lower_name"
  end
end
