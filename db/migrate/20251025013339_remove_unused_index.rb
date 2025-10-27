class RemoveUnusedIndex < ActiveRecord::Migration[8.0]
  def up
    remove_index :articles, name: :index_articles_on_host
    remove_index :articles, name: :index_articles_on_title

    remove_index :comments, name: :index_comments_on_article_id
    remove_index :comments, name: :index_comments_on_user_id
    remove_index :comments, name: :index_comments_on_article_id_and_lft_and_rgt

    remove_index :users, name: :index_users_on_email_address
    remove_index :users, name: :index_users_on_created_at

    remove_index :sessions, name: :index_sessions_on_user_id

    remove_index :preferences, name: :index_preferences_on_name
  end
end
