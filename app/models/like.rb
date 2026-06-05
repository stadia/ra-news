# frozen_string_literal: true
# rbs_inline: enabled

class Like < ApplicationRecord
  belongs_to :actor,
             class_name: "Federails::Actor",
             counter_cache: :likees_count
  belongs_to :likeable,
             polymorphic: true,
             counter_cache: :likers_count

  after_create_commit  :publish_like_activity,  if: :local_actor?
  after_create_commit  :enqueue_thumbnail_generation
  after_destroy_commit :publish_undo_activity,  if: :local_actor?

  class << self
    #: (liker: (User | Federails::Actor)?, likeable_type: String, likeable_ids: Array[Integer]) -> Array[Integer]
    def liked_ids_for(liker:, likeable_type:, likeable_ids:)
      actor = resolve_actor(liker)
      return [] unless actor
      return [] if likeable_ids.blank?

      where(
        actor_id: actor.id,
        likeable_type: likeable_type,
        likeable_id: likeable_ids
      ).pluck(:likeable_id)
    end

    #: (untyped) -> Federails::Actor?
    def resolve_actor(liker)
      case liker
      when nil
        nil
      when Federails::Actor
        liker
      else
        liker.try(:federails_actor)
      end
    end
  end

  private

  def local_actor?
    actor&.local?
  end

  def publish_like_activity
    return unless federatable_likeable?

    likeable.like!(actor: actor)
  end

  def publish_undo_activity
    return unless federatable_likeable?

    like_activity = Federails::Activity
      .where(actor: actor, action: "Like", entity: likeable)
      .order(created_at: :desc)
      .first
    like_activity&.undo!
  end

  def enqueue_thumbnail_generation
    return unless likeable.is_a?(Article)
    return if likeable.thumbnail.attached?

    ArticleThumbnailJob.perform_later(likeable.id)
  end

  def federatable_likeable?
    likeable.is_a?(Federails::DataEntity)
  end
end
