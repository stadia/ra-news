class Chat < ApplicationRecord
  # Includes methods like ask, with_tool, with_instructions, etc.
  # Automatically persists associated messages and tool calls.
  acts_as_chat # Assumes Message and ToolCall model names

  # --- Add your standard Rails model logic below ---
  belongs_to :user, optional: true # Example
  # validates :model_id, presence: true # Example
end
