# services/sitemap_generator.rb
class SitemapService
  def self.call
    SitemapGenerator::Sitemap.default_host = "https://news.stadiasphere.xyz"

    SitemapGenerator::Sitemap.create do
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
      Article.kept.find_in_batches(batch_size: 200, order: [ :desc ]) do |group|
        group.each do |article|
          add article_path(article.slug), lastmod: article.updated_at
        end
      end
    end
    # Compress set to true will generate an '.xml.gz' file
    SitemapGenerator::Sitemap.compress = true
  end
end
