# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module AgentRunner
    extend FunctionLogger
    extend Dry::Monads[:result]

    class << self
      #: (article: Article, prompt: String) -> Dry::Monads::Result
      def run(article:, prompt:)
        message = ArticleAgent.new.ask(prompt)
        raw_content = message.content
        logger.info "Response received for article id: #{article.id}"

        if raw_content.blank?
          article.discard!
          return Failure(message.finish_reason)
        end

        content = raw_content.deep_stringify_keys

        apply_tags(article, content)
        normalize_summary_body(content)
        article.update!(content)
        article.discard! if discard_unrelated_article?(article, content)

        Success(article)
      end

      private

      def apply_tags(article, content)
        return unless content["tags"].present?

        tags = Array(content.delete("tags")).filter_map do |tag|
          next unless tag.is_a?(String) || tag.is_a?(Symbol)

          tag.to_s.downcase.strip.presence
        end.uniq
        return if tags.empty?

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
