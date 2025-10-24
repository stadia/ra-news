# frozen_string_literal: true

class RemoveDuplicateIndexes < ActiveRecord::Migration[8.0]
  def up
    remove_index :sites, name: :index_sites_on_client_and_last_checked_at

    remove_index :sites, name: :index_sites_on_last_checked_at

    remove_index :taggings, name: :index_taggings_on_context

    remove_index :taggings, name: :index_taggings_on_tagger_type_and_tagger_id
  end

  def down
  end
end
