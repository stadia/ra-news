# frozen_string_literal: true
# rbs_inline: enabled

# Longform-specific behavior for Post: publishing, draft/published predicates,
# summary generation, and draft content validation.
#
# The post_type/status enums and longform scopes remain on Post itself,
# since they are referenced as class methods elsewhere.
module Posts
  module Longform
    extend ActiveSupport::Concern

    LONGFORM_SUMMARY_LENGTH = 280

    included do
      validate :validate_longform_draft_content
    end

    #: () -> void
    def publish!
      self.published_at ||= Time.current
      self.status = :published
      save!
    end

    # Soft-deletes the post by marking it discarded. The record is kept so that
    # federation/tombstone lookups still resolve. For a published, locally-owned
    # post we additionally emit an ActivityPub Delete so remote followers drop it;
    # drafts never federated, so nothing is sent for them.
    #: () -> void
    def discard!
      was_published = published?
      update!(status: :discarded)
      create_federails_activity("Delete") if was_published
    end

    #: () -> bool
    def draft_longform?
      longform? && draft?
    end

    #: () -> bool
    def published_longform?
      longform? && published?
    end

    #: () -> String
    def longform_summary
      stripped = ActionView::Base.full_sanitizer.sanitize(body.to_s).squish
      stripped.truncate(LONGFORM_SUMMARY_LENGTH)
    end

    private

    #: () -> void
    def validate_longform_draft_content
      return unless draft_longform?
      return if title.present? || body.present?

      errors.add(:base, I18n.t("posts.longform.errors.blank_draft"))
    end
  end
end
