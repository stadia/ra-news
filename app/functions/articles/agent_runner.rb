# frozen_string_literal: true

module Articles
  module AgentRunner
    module_function

    class << self
      def run(article:, prompt:, logger:)
        message = ArticleAgent.new.ask(prompt)
        raw_content = message.content
        logger.info "Response received for article id: #{article.id}"

        if raw_content.blank?
          article.discard!
          return message.finish_reason
        end

        content = raw_content.deep_stringify_keys

        apply_tags(article, content)
        normalize_summary_body(content)
        article.update!(content)
        article.discard! if discard_unrelated_article?(article, content)

        article
      end

      private

      def apply_tags(article, content)
        return unless content["tags"].present?

        tags = content.delete("tags").map { it.downcase }.uniq
        article.tag_list.add(*tags)
      end

      def normalize_summary_body(content)
        body = content["summary_body"]
        return if body.blank?

        content["summary_body"] = body.to_s
          .gsub("\\n", "\n")
          .gsub("\\t", "\t")
          .gsub("\\r", "\r")
          .gsub("\\\\", "\\")
          .gsub('\"', '"')
      end

      def discard_unrelated_article?(article, content)
        content["is_related"] == false && %w[hacker_news rss gmail rss_page].include?(article.site&.client)
      end
    end
  end
end
