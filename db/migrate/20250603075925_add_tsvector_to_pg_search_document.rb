class AddTsvectorToPgSearchDocument < ActiveRecord::Migration[8.0]
  def change
    add_column :pg_search_documents, :tsvector_content_tsearch, :tsvector
    add_index :pg_search_documents, :tsvector_content_tsearch, using: :gin
    create_trigger(compatibility: 1).on(:pg_search_documents).before(:insert, :update) do
      "new.tsvector_content_tsearch := to_tsvector('pg_catalog.simple', coalesce(new.content,''));"
    end
  end
end
