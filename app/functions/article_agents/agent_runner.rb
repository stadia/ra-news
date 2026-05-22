# frozen_string_literal: true

module ArticleAgents
  module AgentRunner
    extend Dry::Monads[:result]
    module_function

    def run(article:, prompt:, logger:)
      message = ArticleAgent.new.ask(prompt)
      content = message.content.deep_stringify_keys
      logger.info "Response received for article id: #{article.id}"

      if content.blank?
        article.discard!
        return Failure(message.finish_reason)
      end

      apply_tags(article, content)
      normalize_summary_body(content)
      article.update!(content)
      article.discard! if discard_unrelated_article?(article, content)

      Success(article)
    end

    def apply_tags(article, content)
      return unless content["tags"].present?

      tags = content.delete("tags").map { it.downcase }.uniq
      article.tag_list.add(*tags)
    end

    def normalize_summary_body(content)
      return unless content["summary_body"].present?

      content["summary_body"] = content["summary_body"]
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
