# frozen_string_literal: true

module FederailsLikeable
  extend ActiveSupport::Concern

  included do
    on_federails_like_received :apply_like
    on_federails_undo_like_received :apply_unlike
  end

  #: (String actor_url) -> void
  def apply_like(actor_reference)
    actor = resolve_federails_actor(actor_reference)
    return unless actor && persisted?

    actor.like!(self)
  end

  #: (String actor_url) -> void
  def apply_unlike(actor_reference)
    actor = resolve_federails_actor(actor_reference)
    return unless actor && persisted?

    actor.unlike!(self)
  end

  alias_method :apply_undo_like, :apply_unlike

  private

  def resolve_federails_actor(actor_reference)
    actor_url = actor_reference.is_a?(Hash) ? actor_reference["id"] : actor_reference
    return if actor_url.blank?

    Federails::Actor.find_by_federation_url(actor_url)
  end
end
