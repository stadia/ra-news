# This migration comes from fedipub (originally 20260828000000)
class RenameForkTablesToFedipub < ActiveRecord::Migration[7.2]
  # Tables introduced by this fork after upstream's own rename migration was
  # written, so they are not covered by RenameFederailsToFedipub.
  TABLES = {
    'federails_blocks'         => 'fedipub_blocks',
    'federails_featured_items' => 'fedipub_featured_items',
    'federails_featured_tags'  => 'fedipub_featured_tags'
  }.freeze

  def up
    TABLES.each do |old_name, new_name|
      rename_table old_name, new_name if table_exists?(old_name)
    end
  end

  def down
    TABLES.each do |old_name, new_name|
      rename_table new_name, old_name if table_exists?(new_name)
    end
  end
end
