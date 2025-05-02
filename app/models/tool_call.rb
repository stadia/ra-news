# frozen_string_literal: true

# rbs_inline: enabled

class ToolCall < ApplicationRecord
  # Sets up associations to the calling message and the result message.
  acts_as_tool_call # Assumes Message model name

  # --- Add your standard Rails model logic below ---
end
