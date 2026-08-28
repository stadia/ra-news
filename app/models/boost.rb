# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class Boost < ApplicationRecord
  belongs_to :actor,
             class_name: "Fedipub::Actor",
             counter_cache: :boostees_count
  belongs_to :boostable,
             polymorphic: true,
             counter_cache: :boosters_count

  after_create_commit  :publish_boost_activity, if: :local_actor?
  after_create_commit  :enqueue_thumbnail_generation
  after_destroy_commit :publish_undo_activity,  if: :local_actor?

  class << self
    # Article/Post boosts for a profile activity feed, newest first.
    # A class method (not a scope) so the nil early-return is unambiguous.
    #: ((User | Fedipub::Actor)?) -> ActiveRecord::Relation
    def for_actor(actor)
      return none if actor.nil?

      where(actor: actor, boostable_type: %w[Article Post]).order(created_at: :desc)
    end

    #: (booster: (User | Fedipub::Actor)?, boostable_type: String, boostable_ids: Array[Integer]) -> Array[Integer]
    def boosted_ids_for(booster:, boostable_type:, boostable_ids:)
      actor = resolve_actor(booster)
      return [] unless actor
      return [] if boostable_ids.blank?

      where(
        actor_id: actor.id,
        boostable_type: boostable_type,
        boostable_id: boostable_ids
      ).pluck(:boostable_id)
    end

    #: (untyped) -> Fedipub::Actor?
    def resolve_actor(booster)
      case booster
      when nil
        nil
      when Fedipub::Actor
        booster
      else
        booster.try(:fedipub_actor)
      end
    end
  end

  private

  def local_actor?
    actor&.local?
  end

  def publish_boost_activity
    return unless federatable_boostable?

    boostable.announce!(actor: actor)
  end

  def publish_undo_activity
    return unless federatable_boostable?

    announce_activity = Fedipub::Activity
      .where(actor: actor, action: "Announce", entity: boostable)
      .order(created_at: :desc)
      .first
    announce_activity&.undo!
  end

  def enqueue_thumbnail_generation
    return unless boostable.is_a?(Article)
    return if boostable.thumbnail.attached?

    ArticleThumbnailJob.perform_later(boostable.id)
  end

  def federatable_boostable?
    boostable.is_a?(Fedipub::DataEntity)
  end
end
