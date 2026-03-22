# frozen_string_literal: true

class AddLikeesCountToFederailsActors < ActiveRecord::Migration[8.1]
  def change
    add_column :federails_actors, :likees_count, :integer, default: 0, null: false
  end
end
