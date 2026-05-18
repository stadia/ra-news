# frozen_string_literal: true
# rbs_inline: enabled

class LikeFederationService < OperationService
  class << self
    #: (liker: User | Federails::Actor, likeable: Post | Article) -> Dry::Monads::Result
    def publish_like(liker:, likeable:)
      new.call(command: :publish_like, liker:, likeable:)
    end

    #: (liker: User | Federails::Actor, likeable: Post | Article) -> Dry::Monads::Result
    def publish_unlike(liker:, likeable:)
      new.call(command: :publish_unlike, liker:, likeable:)
    end
  end

  #: (command: Symbol, ?liker: (User | Federails::Actor)?, ?likeable: (Post | Article)?) -> Dry::Monads::Result
  def call(command:, liker: nil, likeable: nil)
    case command
    when :publish_like
      step publish_like_activity(liker:, likeable:)
    when :publish_unlike
      step publish_undo_activity(liker:, likeable:)
    else
      Failure(:unknown_command)
    end
  end

  private

  #: (liker: User | Federails::Actor, likeable: Post | Article) -> Dry::Monads::Result
  def publish_like_activity(liker:, likeable:)
    actor = local_actor_for(liker)
    return Success(nil) unless actor && federatable_likeable?(likeable)

    activity = Federails::Activity.create!(
      **activity_attributes(actor:, action: "Like", entity: likeable, likeable:)
    )

    Success(activity)
  end

  #: (liker: User | Federails::Actor, likeable: Post | Article) -> Dry::Monads::Result
  def publish_undo_activity(liker:, likeable:)
    actor = local_actor_for(liker)
    return Success(nil) unless actor && federatable_likeable?(likeable)

    like_activity = Federails::Activity
      .where(actor: actor, action: "Like", entity: likeable)
      .order(created_at: :desc)
      .first
    return Success(nil) unless like_activity

    activity = Federails::Activity.create!(
      **activity_attributes(actor:, action: "Undo", entity: like_activity, likeable:)
    )

    Success(activity)
  end

  #: (Federails::Actor, action: String, entity: ActiveRecord::Base, likeable: Post | Article) -> Hash[Symbol, untyped]
  def activity_attributes(actor:, action:, entity:, likeable:)
    {
      actor:,
      action:,
      entity:
    }.merge(directed_addressing_for(likeable))
  end

  #: (Post | Article) -> Hash[Symbol, Array[String]]
  def directed_addressing_for(likeable)
    recipient = recipient_actor_for(likeable)
    return {} unless recipient&.distant?

    {
      to: [ recipient.federated_url ],
      cc: []
    }
  end

  #: (untyped likeable) -> bool
  def federatable_likeable?(likeable)
    likeable.is_a?(Post) || likeable.is_a?(Article)
  end

  #: (untyped liker) -> Federails::Actor?
  def local_actor_for(liker)
    if liker.is_a?(User)
      liker.federails_actor
    elsif liker.is_a?(Federails::Actor) && liker.local?
      liker
    end
  end

  #: (untyped likeable) -> Federails::Actor?
  def recipient_actor_for(likeable)
    return unless federatable_likeable?(likeable)

    likeable.federails_actor
  end
end
