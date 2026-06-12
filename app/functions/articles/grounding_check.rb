# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module GroundingCheck
    extend FunctionLogger

    THRESHOLD = 0.7

    class << self
      #: (untyped article) -> Hash[Symbol, untyped]?
      def run(article)
        source = article.body.to_s
        summary = summary_payload(article)
        return nil if source.blank? || summary.nil?

        content = judge(source, summary)
        return nil if content.nil?

        score = content["score"].to_f
        {
          grounding_score: score,
          grounding_flagged: score < THRESHOLD,
          grounding_issues: Array(content["unsupported_claims"]),
          grounding_checked_at: Time.current
        }
      rescue StandardError => e
        logger.warn "GroundingCheck failed for article #{article.id}: #{e.message}"
        nil
      end

      private

      #: (untyped article) -> Hash[String, untyped]?
      def summary_payload(article)
        parts = {
          "summary_key" => Array(article.summary_key),
          "summary_introduction" => article.summary_introduction,
          "summary_body" => article.summary_body,
          "summary_conclusion" => article.summary_conclusion
        }
        parts.values.any?(&:present?) ? parts : nil
      end

      #: (String source, Hash[String, untyped] summary) -> Hash[String, untyped]?
      def judge(source, summary)
        message = GroundingAgent.new.ask(prompt(source, summary))
        message.content&.deep_stringify_keys
      end

      #: (String source, Hash[String, untyped] summary) -> String
      def prompt(source, summary)
        <<~PROMPT
          [SOURCE]
          #{source}

          [SUMMARY]
          #{JSON.pretty_generate(summary)}
        PROMPT
      end
    end
  end
end
