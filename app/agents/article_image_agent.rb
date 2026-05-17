# frozen_string_literal: true
# rbs_inline: enabled

class ArticleImageAgent < RubyLLM::Agent
  model "nano-banana-pro-preview"
  # model "gemini-3-pro-image-preview"

  temperature 0.5
end
