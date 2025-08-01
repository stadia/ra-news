# frozen_string_literal: true

# rbs_inline: enabled

class SitemapService < ApplicationService
  # This service generates a sitemap for the application.
  # It uses the SitemapGenerator gem to create the sitemap XML file.
  # The sitemap will include links to articles that have a slug and are kept (not deleted).
  # The sitemap is compressed into an XML.gz file.

  # Call this method to generate the sitemap.
  def call
    SitemapGenerator::Sitemap.create(
      default_host: "https://ruby-news.kr",
      sitemaps_path: "sitemaps/"
    ) do
      # Put links creation logic here.
      #
      # The root path '/' and sitemap index file are added automatically for you.
      # Links are added to the Sitemap in the order they are specified.
      #
      # Usage: add(path, options={})
      #        (default options are used if you don't specify)
      #
      # Defaults: :priority => 0.5, :changefreq => 'weekly',
      #           :lastmod => Time.now, :host => default_host
      #
      # Examples:
      #
      # Add '/articles'
      #
      #   add articles_path, :priority => 0.7, :changefreq => 'daily'
      Article.kept.where.not(slug: nil).find_in_batches(batch_size: 200, order: [ :desc ]) do |group|
        group.each do |article|
          add article_path(article.slug), lastmod: article.updated_at
        end
      end
    end
    # Compress set to true will generate an '.xml.gz' file
    SitemapGenerator::Sitemap.compress = true
  end
end
