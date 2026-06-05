# frozen_string_literal: true

class ReplaceLikesPolymorphicLikerWithActor < ActiveRecord::Migration[8.1]
  def up
    add_reference :likes, :actor, foreign_key: { to_table: :federails_actors }, null: true

    execute(<<~SQL.squish)
      UPDATE likes
      SET actor_id = federails_actors.id
      FROM federails_actors
      WHERE likes.liker_type = 'User'
        AND federails_actors.entity_type = 'User'
        AND federails_actors.entity_id = likes.liker_id
    SQL

    execute(<<~SQL.squish)
      UPDATE likes
      SET actor_id = liker_id
      WHERE liker_type = 'Federails::Actor'
    SQL

    execute("DELETE FROM likes WHERE actor_id IS NULL")

    change_column_null :likes, :actor_id, false

    remove_index :likes, name: "index_likes_on_liker_and_likeable"
    remove_index :likes, name: "index_likes_on_liker"
    remove_column :likes, :liker_id
    remove_column :likes, :liker_type

    add_index :likes, [ :actor_id, :likeable_type, :likeable_id ],
              unique: true, name: "index_likes_on_actor_and_likeable"

    reset_counters_for_likes
  end

  def down
    add_column :likes, :liker_id, :bigint
    add_column :likes, :liker_type, :string

    execute(<<~SQL.squish)
      UPDATE likes
      SET liker_id = federails_actors.entity_id,
          liker_type = federails_actors.entity_type
      FROM federails_actors
      WHERE federails_actors.id = likes.actor_id
        AND federails_actors.entity_type = 'User'
    SQL

    execute(<<~SQL.squish)
      UPDATE likes
      SET liker_id = actor_id,
          liker_type = 'Federails::Actor'
      WHERE liker_id IS NULL
    SQL

    change_column_null :likes, :liker_id, false
    change_column_null :likes, :liker_type, false

    remove_index :likes, name: "index_likes_on_actor_and_likeable"
    add_index :likes, [ :liker_type, :liker_id, :likeable_type, :likeable_id ],
              unique: true, name: "index_likes_on_liker_and_likeable"
    add_index :likes, [ :liker_type, :liker_id ], name: "index_likes_on_liker"

    remove_reference :likes, :actor, foreign_key: { to_table: :federails_actors }
  end

  private

  def reset_counters_for_likes
    execute(<<~SQL.squish)
      UPDATE articles SET likers_count = COALESCE((
        SELECT COUNT(*) FROM likes WHERE likes.likeable_type = 'Article' AND likes.likeable_id = articles.id
      ), 0)
    SQL

    execute(<<~SQL.squish)
      UPDATE posts SET likers_count = COALESCE((
        SELECT COUNT(*) FROM likes WHERE likes.likeable_type = 'Post' AND likes.likeable_id = posts.id
      ), 0)
    SQL

    execute(<<~SQL.squish)
      UPDATE federails_actors SET likees_count = COALESCE((
        SELECT COUNT(*) FROM likes WHERE likes.actor_id = federails_actors.id
      ), 0)
    SQL
  end
end
