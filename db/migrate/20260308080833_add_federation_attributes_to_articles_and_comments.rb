class AddFederationAttributesToArticlesAndComments < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :federated_url, :string, null: true, default: nil
    add_reference :articles, :federails_actor, null: true

    add_column :comments, :federated_url, :string, null: true, default: nil
    add_reference :comments, :federails_actor, null: true
  end
end
