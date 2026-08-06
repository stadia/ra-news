# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# Renders an Article as Markdown (used by the `.md` response format). Kept out of
# the Article model so its I18n-heavy display formatting doesn't add to the
# model's surface; reads only the article's public locale-aware display methods.
module Articles
  module Markdown
    extend FunctionLogger

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
        # summary_key는 jsonb이라 선언 타입(Array[String] | String | nil) 밖의 형태(Hash 등)도
        # 런타임에 올 수 있다 — 경계에서 untyped로 받아 형태를 직접 검사한다.
        items = T.cast(article.display_summary_key, T.untyped)
        return if items.blank?

        items = [ items ] if items.is_a?(String)
        unless items.is_a?(Array)
          # 깨진 출력(- ["k", 1]) 대신 로그를 남기고 섹션을 생략한다.
          logger.error "summary_key has unexpected shape for article #{article.id}: #{items.class}"
          return
        end

        "\n## #{I18n.t('articles.markdown.summary_heading')}\n" \
          "#{items.map { |item| "- #{item}" }.join("\n")}"
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
