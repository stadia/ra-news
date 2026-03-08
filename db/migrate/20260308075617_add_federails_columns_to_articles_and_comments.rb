class AddFederailsColumnsToArticlesAndComments < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :federated_url, :string, null: true, default: nil
    add_reference :articles, :federails_actor, foreign_key: { to_table: :federails_actors }, null: true, default: nil

    add_column :comments, :federated_url, :string, null: true, default: nil
    add_reference :comments, :federails_actor, foreign_key: { to_table: :federails_actors }, null: true, default: nil
  end
end
