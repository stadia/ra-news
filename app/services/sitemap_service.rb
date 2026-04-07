# frozen_string_literal: true

# rbs_inline: enabled

class SitemapService < OperationService
  # This service generates a sitemap for the application.
  # It uses the SitemapGenerator gem to create the sitemap XML file.
  # The sitemap will include links to articles that have a slug and are kept (not deleted).
  # The sitemap is compressed into an XML.gz file.

  # Call this method to generate the sitemap.
  def call
    SitemapGenerator::Sitemap.compress = true
    SitemapGenerator::Sitemap.create(
      default_host: "https://ruby-news.kr",
      sitemaps_path: "sitemaps/"
    ) do
      add articles_path, lastmod: Date.current.iso8601

      # find_in_batches는 order: 옵션을 지원하지 않으므로 scope에서 order() 후 적용.
      # lastmod는 updated_at 대신 published_at 사용
      # (updated_at은 배경 Job이 건드릴 때마다 갱신되어 Google 오탐 발생)
      Article.kept.confirmed.without_toast.find_in_batches(batch_size: 500) do |group|
        group.each do |article|
          add article_path(article), lastmod: (article.published_at || article.updated_at)&.iso8601
        end
      end
    end
    Success(true)
  end

  def self.call
    new.call
  end
end
