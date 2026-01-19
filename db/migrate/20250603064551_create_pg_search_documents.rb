class CreatePgSearchDocuments < ActiveRecord::Migration[8.0]
  def up
    say_with_time("Creating table for pg_search multisearch") do
      create_table :pg_search_documents do |t|
        t.text :content
        t.belongs_to :searchable, polymorphic: true, index: true
        t.timestamps null: false
      end
    end
    add_index :pg_search_documents, %[to_tsvector('simple', coalesce("pg_search_documents"."content"::text, ''))], using: :gin, opclass: :gin_bigm_ops
  end

  def down
    say_with_time("Dropping table for pg_search multisearch") do
      drop_table :pg_search_documents
    end
  end
end
