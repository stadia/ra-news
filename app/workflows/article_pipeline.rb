# frozen_string_literal: true

# rbs_inline: enabled

class ArticlePipeline < ApplicationWorkflow
  description "Processes content through extraction, classification, and formatting"

  input do
    required :raw_content, String
    required :title, String
    required :url, String
    optional :content_type, String, default: "html"
  end

  step :data_prepper, Articles::DataPrepperAgent
  step :knowledge, Articles::KnowledgeAgent
end
