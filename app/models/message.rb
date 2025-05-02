# frozen_string_literal: true

# rbs_inline: enabled

class Message < ApplicationRecord
  # Provides methods like tool_call?, tool_result?
  acts_as_message # Assumes Chat and ToolCall model names

  # --- Add your standard Rails model logic below ---
end
