# frozen_string_literal: true

# rbs_inline: enabled

class Post < ApplicationRecord
  acts_as_nested_set
  acts_as_likeable

  belongs_to :user, optional: true

  validates :body, presence: true

  validate :validate_user_or_actor
  validate :validate_parent_post

  include Federails::DataEntity

  belongs_to :federails_actor, class_name: "Federails::Actor", optional: true
  # Federails::DataEntity가 추가하는 federails_actor presence 검증을 제거
  federails_actor_presence_validator = _validate_callbacks
    .map(&:filter)
    .find do |filter|
      filter.is_a?(ActiveRecord::Validations::PresenceValidator) &&
        filter.attributes == [ :federails_actor ]
    end
  skip_callback :validate, :before, federails_actor_presence_validator if federails_actor_presence_validator

  acts_as_federails_data handles: "Note",
    actor_entity_method: :federation_actor_entity,
    should_federate_method: :should_federate?

  on_federails_delete_requested -> { logger.info { "Federated post deletion requested #{id}" }; destroy! }

  def federation_actor_entity
    user || federails_actor
  end

  def should_federate?
    federation_actor_entity.present?
  end

  def to_activitypub_object
    custom = {}
    if parent.present?
      custom["inReplyTo"] = parent.federated_url || Rails.application.routes.url_helpers.post_url(parent)
    end
    Federails::DataTransformer::Note.to_federation(self, content: body, custom: custom)
  end

  def likes_count
    likers_count.to_i
  end

  private

  def set_federails_actor
    return if federation_actor_entity.nil?

    super
  end

  def validate_user_or_actor
    unless user_id.present? || federails_actor_id.present?
      errors.add(:base, "user 또는 federails_actor가 필요합니다")
    end
  end

  def validate_parent_post
    return unless parent_id.present?

    if parent.nil?
      errors.add(:parent_id, "원본 포스트를 찾을 수 없습니다.")
    end
  end

  class << self
    def from_activitypub_object(hash)
      in_reply_to = hash["inReplyTo"].to_s

      object = {
        federated_url: hash["id"],
        body: ActionController::Base.helpers.strip_tags(hash["content"]).squish
      }

      if in_reply_to.present?
        post_id = in_reply_to[%r{/posts/(\d+)}, 1]
        if post_id.present?
          object[:parent_id] = post_id
        else
          parent = Post.find_by(federated_url: in_reply_to)
          object[:parent_id] = parent.id if parent
        end
      end

      object
    end

    def handle_federated_object?(hash)
      in_reply_to = hash["inReplyTo"].to_s

      # inReplyTo가 없으면 원문 → 수락
      return true if in_reply_to.blank?

      # inReplyTo가 로컬 post를 가리키면 수락
      local_host = Rails.application.routes.default_url_options[:host]
      return true if local_host.present? && in_reply_to.include?(local_host) && in_reply_to.include?("/posts/")

      # inReplyTo가 기존 post의 federated_url이면 수락
      Post.exists?(federated_url: in_reply_to)
    end
  end
end
