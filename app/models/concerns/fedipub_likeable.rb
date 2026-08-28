# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module FedipubLikeable
  extend ActiveSupport::Concern
  include Fedipub::HandlesSocialActivities

  included do
    on_fedipub_like_received :apply_remote_like
    on_fedipub_undo_like_received :apply_remote_unlike
  end

  #: (untyped actor_reference) -> void
  def apply_remote_like(actor_reference)
    actor = resolve_fedipub_actor(actor_reference)
    return unless actor && persisted?

    Like.create_or_find_by!(actor: actor, likeable: self)
  end

  #: (untyped actor_reference) -> void
  def apply_remote_unlike(actor_reference)
    actor = resolve_fedipub_actor(actor_reference)
    return unless actor && persisted?

    Like.where(actor: actor, likeable: self).destroy_all
  end

  private

  def resolve_fedipub_actor(actor_reference)
    actor_url = actor_reference.is_a?(Hash) ? actor_reference["id"] : actor_reference
    return if actor_url.blank?

    Fedipub::Actor.find_by_federation_url(actor_url)
  end
end
