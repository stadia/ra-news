# This migration comes from federails (originally 20260309022820)
class AddFederatedUrlToFederailsActivities < ActiveRecord::Migration[7.2]
  def change
    add_column :federails_activities, :federated_url, :string
    add_index :federails_activities, :federated_url, unique: true
  end
end
