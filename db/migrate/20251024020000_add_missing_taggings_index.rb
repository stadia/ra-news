# frozen_string_literal: true

class AddMissingTaggingsIndex < ActiveRecord::Migration[8.0]
  def up
    # Add optimized composite index for common tagging queries
    # Query pattern: WHERE taggable_id = ? AND taggable_type = ? AND tagger_id = ? AND context = ?
    unless index_exists?(:taggings, [ :taggable_id, :taggable_type, :tagger_id, :context ])
      add_index :taggings, [ :taggable_id, :taggable_type, :tagger_id, :context ]
    end
  end

  def down
    # Remove the composite index
    remove_index :taggings, name: 'index_taggings_on_taggable_id_and_taggable_type_and_tagger_id_and_context', if_exists: true
  end
end
