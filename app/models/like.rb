# frozen_string_literal: true

class Like < Socialization::ActiveRecordStores::Like
  after_like :publish_federated_like
  after_unlike :publish_federated_unlike

  class << self
    def publish_federated_like(liker, likeable)
      LikeFederationService.publish_like(liker:, likeable:)
    end

    def publish_federated_unlike(liker, likeable)
      LikeFederationService.publish_unlike(liker:, likeable:)
    end
  end
end
