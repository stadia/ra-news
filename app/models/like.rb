# frozen_string_literal: true
# rbs_inline: enabled

class Like < Socialization::ActiveRecordStores::Like
  after_like :handle_after_like
  after_unlike :publish_federated_unlike

  class << self
    #: (User?, String, Array[Integer]) -> Array[Integer]
    def liked_ids_for(liker:, likeable_type:, likeable_ids:)
      return [] unless liker
      return [] if likeable_ids.empty?

      where(
        liker:,
        likeable_type:,
        likeable_id: likeable_ids
      ).pluck(:likeable_id)
    end

    #: (User, ActiveRecord::Base) -> void
    def handle_after_like(liker, likeable)
      publish_federated_like(liker, likeable)
      enqueue_thumbnail_generation(liker, likeable)
    end

    #: (User, ActiveRecord::Base) -> void
    def publish_federated_like(liker, likeable)
      LikeFederationService.publish_like(liker:, likeable:)
    end

    #: (User, ActiveRecord::Base) -> void
    def enqueue_thumbnail_generation(liker, likeable)
      return unless likeable.is_a?(Article)
      return if likeable.thumbnail.attached?

      ArticleThumbnailJob.perform_later(likeable.id)
    end

    #: (User, ActiveRecord::Base) -> void
    def publish_federated_unlike(liker, likeable)
      LikeFederationService.publish_unlike(liker:, likeable:)
    end
  end
end
