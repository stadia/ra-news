# frozen_string_literal: true

# rbs_inline: enabled

class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
