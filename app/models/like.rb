# frozen_string_literal: true

# rbs_inline: enabled

class Like < Socialization::ActiveRecordStores::Like
  after_like :publish_federated_like
  after_unlike :publish_federated_unlike

  class << self
    #: (User, ActiveRecord::Base) -> void
    def publish_federated_like(liker, likeable)
      LikeFederationService.publish_like(liker:, likeable:)
    end

    #: (User, ActiveRecord::Base) -> void
    def publish_federated_unlike(liker, likeable)
      LikeFederationService.publish_unlike(liker:, likeable:)
    end
  end
end
