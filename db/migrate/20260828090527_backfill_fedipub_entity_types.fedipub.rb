# This migration comes from fedipub (originally 20260828000001)
class BackfillFedipubEntityTypes < ActiveRecord::Migration[7.2]
  # Activities created before the rename still carry the old namespace in their
  # polymorphic entity_type: "Federails::Actor" for Update/Delete/Announce/Like
  # targeting an actor, "Federails::Activity" for Undo. RenameFederailsToFedipub
  # only renames tables and indexes, so without this backfill Activity#entity
  # silently returns nil for those rows.
  OLD_PREFIX = 'Federails::'.freeze
  NEW_PREFIX = 'Fedipub::'.freeze

  def up
    move_entity_types OLD_PREFIX, NEW_PREFIX
  end

  def down
    move_entity_types NEW_PREFIX, OLD_PREFIX
  end

  private

  def move_entity_types(from, to)
    return unless table_exists?(:fedipub_activities)

    entity_types_starting_with(from).each do |entity_type|
      execute(<<~SQL.squish)
        UPDATE fedipub_activities
        SET entity_type = #{quote(entity_type.sub(from, to))}
        WHERE entity_type = #{quote(entity_type)}
      SQL
    end
  end

  def entity_types_starting_with(prefix)
    select_values(<<~SQL.squish)
      SELECT DISTINCT entity_type FROM fedipub_activities
      WHERE entity_type LIKE #{quote("#{prefix}%")}
    SQL
  end
end
