# frozen_string_literal: true

module FederailsBoostable
  extend ActiveSupport::Concern
  include Federails::HandlesSocialActivities

  included do
    on_federails_announce_received :apply_remote_boost
    on_federails_undo_announce_received :apply_remote_unboost
  end

  #: (untyped actor_reference) -> void
  def apply_remote_boost(actor_reference)
    actor = resolve_federails_actor(actor_reference)
    return unless actor && persisted?

    Boost.create_or_find_by!(actor: actor, boostable: self)
  end

  #: (untyped actor_reference) -> void
  def apply_remote_unboost(actor_reference)
    actor = resolve_federails_actor(actor_reference)
    return unless actor && persisted?

    Boost.where(actor: actor, boostable: self).destroy_all
  end

  private

  def resolve_federails_actor(actor_reference)
    actor_url = actor_reference.is_a?(Hash) ? actor_reference["id"] : actor_reference
    return if actor_url.blank?

    Federails::Actor.find_by_federation_url(actor_url)
  end
end
