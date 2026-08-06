# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# Renders an Article as Markdown (used by the `.md` response format). Kept out of
# the Article model so its I18n-heavy display formatting doesn't add to the
# model's surface; reads only the article's public locale-aware display methods.
module Articles
  module Markdown
    class << self
      #: (Article article) -> String
      def render(article)
        [
          "# #{article.display_title}\n",
          "- **#{I18n.t('articles.markdown.source_url')}**: #{article.url}",
          "- **#{I18n.t('articles.markdown.ruby_news_url')}**: #{Rails.application.routes.url_helpers.article_url(article)}",
          (article.published_at.present? ? "- **#{I18n.t('articles.markdown.published_at')}**: #{article.published_at}" : nil),
          summary_key_section(article),
          introduction_section(article),
          body_section(article),
          conclusion_section(article)
        ].compact.join("\n")
      end

      private

      #: (Article article) -> String?
      def summary_key_section(article)
        return if article.display_summary_key.blank?

        "\n## #{I18n.t('articles.markdown.summary_heading')}\n" \
          "#{Array(article.display_summary_key).map { |item| "- #{item}" }.join("\n")}"
      end

      #: (Article article) -> String?
      def introduction_section(article)
        detail = article.display_summary_detail
        return unless detail.is_a?(Hash) && detail["introduction"].present?

        "\n## #{I18n.t('articles.markdown.introduction_heading')}\n#{detail['introduction']}"
      end

      #: (Article article) -> String?
      def body_section(article)
        return if article.display_summary_body.blank?

        "\n## #{I18n.t('articles.markdown.body_heading')}\n#{article.display_summary_body}"
      end

      #: (Article article) -> String?
      def conclusion_section(article)
        detail = article.display_summary_detail
        return unless detail.is_a?(Hash) && detail["conclusion"].present?

        "\n## #{I18n.t('articles.markdown.conclusion_heading')}\n#{detail['conclusion']}"
      end
    end
  end
end
