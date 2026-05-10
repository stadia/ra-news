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
    recipient = recipient_actor_for(likeable)
    return Success(nil) unless actor && recipient&.distant?

    activity = Federails::Activity.create!(
      actor: actor,
      action: "Like",
      entity: likeable,
      to: [ recipient.federated_url ],
      cc: []
    )

    Success(activity)
  end

  #: (liker: User | Federails::Actor, likeable: Post | Article) -> Dry::Monads::Result
  def publish_undo_activity(liker:, likeable:)
    actor = local_actor_for(liker)
    recipient = recipient_actor_for(likeable)
    return Success(nil) unless actor && recipient&.distant?

    like_activity = Federails::Activity
      .where(actor: actor, action: "Like", entity: likeable)
      .order(created_at: :desc)
      .first
    return Success(nil) unless like_activity

    activity = Federails::Activity.create!(
      actor: actor,
      action: "Undo",
      entity: like_activity,
      to: [ recipient.federated_url ],
      cc: []
    )

    Success(activity)
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
    return unless likeable.is_a?(Post) || likeable.is_a?(Article)

    likeable.federails_actor
  end
end
