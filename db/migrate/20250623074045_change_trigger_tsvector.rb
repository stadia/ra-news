class ChangeTriggerTsvector < ActiveRecord::Migration[8.0]
  def up
    execute "CREATE EXTENSION IF NOT EXISTS textsearch_ko;" unless Rails.env.test?
    create_trigger(compatibility: 1).on(:pg_search_documents).before(:insert, :update) do
      "new.tsvector_content_tsearch := to_tsvector('korean', coalesce(new.content,''));"
    end
  end
end
