# This migration comes from federails (originally 20260309040000)
class AddBtoBccAudienceToFederailsActivities < ActiveRecord::Migration[7.2]
  def change
    add_column :federails_activities, :bto, :string
    add_column :federails_activities, :bcc, :string
    add_column :federails_activities, :audience, :string
  end
end
