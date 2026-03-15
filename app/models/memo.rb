# frozen_string_literal: true

class Memo < ApplicationRecord
  include Discard::Model
  self.discard_column = :deleted_at

  MAX_BODY_LENGTH = 500

  belongs_to :user
  has_many :comments, dependent: :nullify

  validates :body, presence: true, length: { minimum: 1, maximum: MAX_BODY_LENGTH }

  default_scope { kept }

  include Federails::DataEntity

  acts_as_federails_data handles: "Note",
    actor_entity_method: :user,
    soft_deleted_method: :discarded?,
    soft_delete_date_method: :deleted_at,
    should_federate_method: :should_federate?

  on_federails_delete_requested -> { logger.info { "Federated memo deletion requested #{id}" }; discard! }

  on_federails_undelete_requested :undiscard!

  after_discard do
    create_federails_activity "Delete"
  end

  after_undiscard do
    create_federails_activity "Undo"
  end

  def to_activitypub_object
    memo_url = Rails.application.routes.url_helpers.memo_url(self)
    content = body

    Federails::DataTransformer::Note.to_federation(
      self, content: content, custom: { "url" => memo_url }
    )
  end

  def should_federate?
    user.present?
  end

  private

  def create_federails_activity(action)
    if action == "Update" && !Federails::Activity.exists?(entity: self, action: "Create")
      action = "Create"
    end
    super(action)
  end

  class << self
    def from_activitypub_object(hash)
      {
        federated_url: hash["id"],
        body: ActionController::Base.helpers.strip_tags(hash["content"]).squish
      }
    end

    # Memo는 외부에서 들어오는 Federation을 처리하지 않음 (발신 전용)
    def handle_federated_object?(hash)
      false
    end
  end
end
