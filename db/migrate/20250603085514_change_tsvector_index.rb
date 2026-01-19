class ChangeTsvectorIndex < ActiveRecord::Migration[8.0]
  def up
    remove_index :pg_search_documents, name: "idx_on_to_tsvector_simple_coalesce_pg_search_docume_39455b0632" if index_exists?(:pg_search_documents, "to_tsvector('simple'::regconfig, COALESCE(content, ''::text))", name: "idx_on_to_tsvector_simple_coalesce_pg_search_docume_39455b0632")
    remove_index :pg_search_documents, :tsvector_content_tsearch, using: :gin if index_exists?(:pg_search_documents, :tsvector_content_tsearch, name: "index_pg_search_documents_on_tsvector_content_tsearch")
    say_with_time("최적화된 GIN 인덱스 생성") do
      execute("CREATE INDEX index_pg_search_documents_on_tsvector_content_tsearch ON pg_search_documents USING GIN (tsvector_content_tsearch) WITH (fastupdate = off);")
    end
  end

  def down
    remove_index :pg_search_documents, name: "index_pg_search_documents_on_tsvector_content_tsearch"
    add_index :pg_search_documents, :tsvector_content_tsearch, using: :gin
  end
end
