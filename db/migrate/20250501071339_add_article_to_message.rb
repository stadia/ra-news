class AddArticleToMessage < ActiveRecord::Migration[8.0]
  def up
    drop_table :chats if table_exists?(:chats)
    remove_column :messages, :chat_id, :integer if column_exists?(:messages, :chat_id)
    add_column :articles, :summary_key, :jsonb
    add_column :articles, :summary_detail, :jsonb
    add_column :articles, :title_ko, :string
  end

  def down
    remove_column :articles, :summary_key, :jsonb
    remove_column :articles, :summary_detail, :jsonb
    remove_column :articles, :title_ko, :string
  end
end
