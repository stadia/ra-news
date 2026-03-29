# frozen_string_literal: true

module FederailsLikeable
  extend ActiveSupport::Concern

  included do
    on_federails_like_received :apply_like
    on_federails_undo_like_received :apply_unlike
  end

  private

  #: (String actor_url) -> void
  def apply_like(actor_url)
    actor = Federails::Actor.find_by(federated_url: actor_url)
    return unless actor

    actor.like!(self)
  end

  #: (String actor_url) -> void
  def apply_unlike(actor_url)
    actor = Federails::Actor.find_by(federated_url: actor_url)
    return unless actor

    actor.unlike!(self)
  end

  alias_method :apply_undo_like, :apply_unlike
end
