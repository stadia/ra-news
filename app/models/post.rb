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

  acts_as_taggable_on :tags

  on_federails_delete_requested -> { logger.info { "Federated post deletion requested #{id}" }; destroy! }

  #: () -> (User | Federails::Actor)?
  def federation_actor_entity
    user || federails_actor
  end

  #: () -> bool
  def should_federate?
    federation_actor_entity.present?
  end

  #: () -> Hash[String, untyped]
  def to_activitypub_object
    custom = {}
    if parent.present?
      custom["inReplyTo"] = parent.federated_url || Rails.application.routes.url_helpers.post_url(parent)
    end

    if tag_list.any?
      custom["tag"] = tag_list.map do |name|
        { "type" => "Hashtag", "name" => "##{name}", "href" => "#{Rails.application.routes.default_url_options[:host]}/tags/#{name}" }
      end
    end

    if media_attachments.any?
      custom["attachment"] = media_attachments
    end

    Federails::DataTransformer::Note.to_federation(self, content: body, custom: custom)
  end

  #: () -> Integer
  def likes_count
    likers_count.to_i
  end

  private

  #: () -> void
  def set_federails_actor
    return if federation_actor_entity.nil?

    super
  end

  #: () -> void
  def validate_user_or_actor
    unless user_id.present? || federails_actor_id.present?
      errors.add(:base, "user 또는 federails_actor가 필요합니다")
    end
  end

  #: () -> void
  def validate_parent_post
    return unless parent_id.present?

    if parent.nil?
      errors.add(:parent_id, "원본 포스트를 찾을 수 없습니다.")
    end
  end

  class << self
    #: (Hash[String, untyped]) -> Hash[Symbol, untyped]
    def from_activitypub_object(hash)
      in_reply_to = hash["inReplyTo"].to_s

      object = {
        federated_url: hash["id"],
        url: hash["url"],
        title: hash["summary"].presence,
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

      # Mastodon 이미지 첨부 파싱
      attachments = Array(hash["attachment"]).select { |a| a.is_a?(Hash) && (a["type"] == "Document" || a["type"] == "Image") }
      object[:media_attachments] = attachments.map do |a|
        { "url" => a["url"], "mediaType" => a["mediaType"], "name" => a["name"] }.compact
      end

      # Mastodon 해시태그 파싱
      hashtags = Array(hash["tag"]).select { |t| t.is_a?(Hash) && t["type"] == "Hashtag" }
      object[:tag_list] = hashtags.map { |t| t["name"].to_s.delete_prefix("#") }.uniq.join(", ") if hashtags.any?

      object
    end

    #: (Hash[String, untyped]) -> bool
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
