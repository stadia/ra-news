# frozen_string_literal: true

class AddForeignKeysForArticlesAndPosts < ActiveRecord::Migration[8.1]
  def up
    change_column_default :articles, :site_id, from: 0, to: nil
    change_column_null    :articles, :site_id, true

    execute <<~SQL.squish
      UPDATE articles
      SET site_id = NULL
      WHERE site_id = 0
         OR site_id NOT IN (SELECT id FROM sites)
    SQL

    add_foreign_key :articles, :sites,            column: :site_id,            on_delete: :nullify
    add_foreign_key :articles, :users,            column: :user_id,            on_delete: :nullify
    add_foreign_key :articles, :federails_actors, column: :federails_actor_id, on_delete: :nullify

    add_foreign_key :posts, :users,            column: :user_id,            on_delete: :nullify
    add_foreign_key :posts, :federails_actors, column: :federails_actor_id, on_delete: :nullify
    add_foreign_key :posts, :posts,            column: :parent_id,          on_delete: :nullify
  end

  def down
    remove_foreign_key :posts,    column: :parent_id
    remove_foreign_key :posts,    column: :federails_actor_id
    remove_foreign_key :posts,    column: :user_id

    remove_foreign_key :articles, column: :federails_actor_id
    remove_foreign_key :articles, column: :user_id
    remove_foreign_key :articles, column: :site_id

    change_column_null    :articles, :site_id, false, 0
    change_column_default :articles, :site_id, from: nil, to: 0
  end
end
