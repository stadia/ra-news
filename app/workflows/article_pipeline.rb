# frozen_string_literal: true

# rbs_inline: enabled

class ArticlePipeline < RubyLLM::Agents::Workflow
  description "Processes content through extraction, classification, and formatting"

  input do
    required :raw_content, String
    optional :content_type, String, default: "html"
  end

  step :data_prepper,  Articles::DataPrepperAgent
  step :summarizer, Articles::SummarizerAgent
end