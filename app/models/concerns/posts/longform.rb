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

    # Prepended onto the including class so it sits ahead of
    # Federails::DataEntity in the ancestor chain. That lets us swallow the
    # automatic "Update" activity fired during a draft's first publish; publish!
    # emits a "Create" explicitly instead (see #publish!).
    module FederailsActivityOverride
      private

      def create_federails_activity(action, **)
        return if action == "Update" && @suppress_federails_update

        super
      end
    end

    included do
      validate :validate_longform_draft_content
      prepend FederailsActivityOverride
    end

    #: () -> void
    def publish!
      # A draft never federated, so remotes hold no object for it. Federails'
      # after_update would emit an "Update" on this save, which remotes drop
      # (nothing to update). Suppress that Update and emit a "Create" instead so
      # the first publish actually delivers the post. Re-publishing an already
      # published post keeps the normal Update path.
      publishing_draft = draft?
      @suppress_federails_update = publishing_draft

      self.published_at ||= Time.current
      self.status = :published
      save!

      create_federails_activity("Create") if publishing_draft && should_federate?
    ensure
      @suppress_federails_update = false
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
