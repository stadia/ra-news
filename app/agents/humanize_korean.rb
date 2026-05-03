# frozen_string_literal: true
# rbs_inline: enabled

class HumanizeKorean < RubyLLM::Agent
  model "gemini-3-flash-preview"
  skills "app/skills", only: [ "humanize-korean" ]
end
