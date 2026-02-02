# frozen_string_literal: true

# rbs_inline: enabled

class ArticlePipeline < ApplicationWorkflow
  description "Processes content through extraction, classification, and formatting"

  timeout 180

  input do
    required :raw_content, String
    required :title, String
    required :url, String
    optional :content_type, String, default: "html"
  end

  # Step 1: 콘텐츠 정제 및 청킹
  step :data_prepper, Articles::DataPrepperAgent

  # Step 2: 지식 구조화 (글로벌 맥락, 아키텍처 설계)
  step :knowledge, Articles::KnowledgeAgent,
       input: -> {
         {
           cleaned_content: data_prepper.cleaned_content,
           semantic_chunks: data_prepper.semantic_chunks
         }
       }

  # Step 3: 외부 컨텍스트 리서치
  # step :context_provider, Articles::ContextProviderAgent,
  #      input: -> {
  #        {
  #          knowledge_architecture: knowledge.knowledge_architecture
  #        }
  #      }

  # Step 4: 요약, 번역 작성
  step :technical_writer, Articles::TechnicalWriterAgent,
       input: -> {
         {
           title: input.title,
           semantic_chunks: data_prepper.semantic_chunks,
           global_context: knowledge.global_context,
           knowledge_architecture: knowledge.knowledge_architecture
           # contextual_insights: context_provider.contextual_insights
         }
       }

  # Step 5: 한국어 번역 (전체 콘텐츠)
  # step :translator, Articles::TranslatorAgent,
  #      input: -> {
  #        {
  #          title: input.title,
  #          summary_key: technical_writer.summary_key,
  #          summary_detail: technical_writer.summary_detail,
  #          summary_body: technical_writer.summary_body
  #        }
  #      }

  step :editor_optimizer, Articles::EditorOptimizerAgent,
       input: -> {
         {
           title: technical_writer.title_ko,
           summary_key: technical_writer.summary_key,
           summary_detail: technical_writer.summary_detail,
           summary_body: technical_writer.summary_body,
           content: data_prepper.cleaned_content
         }
       }
end
