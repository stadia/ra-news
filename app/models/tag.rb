# typed: strong
# frozen_string_literal: true
# rbs_inline: enabled

class Tag < ActsAsTaggableOn::Tag
  scope :confirmed, -> { where(is_confirmed: true) }

  scope :unconfirmed, -> { where(is_confirmed: false) }
end
