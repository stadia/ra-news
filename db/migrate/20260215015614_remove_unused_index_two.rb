class RemoveUnusedIndexTwo < ActiveRecord::Migration[8.1]
  def change
    remove_index :articles, [ :site_id, :published_at ], name: 'index_articles_on_site_and_published_at'
    remove_index :sites, :deleted_at, name: 'index_sites_on_deleted_at'
    remove_index :roles, :name, name: 'index_roles_on_name'
    remove_index :comments, [ :article_id, :created_at, :user_id ], name: 'index_comments_on_article_id_and_created_at_and_user_id'
  end
end
