# frozen_string_literal: true

class Components::Layout::StructuredData < Components::Base
  def view_template
    render_schema_org
  end

  private

  def render_schema_org
    vc = view_context
    web_site = vc.instance_variable_get(:@web_site)
    news_media = vc.instance_variable_get(:@news_media_organization)
    news_article = vc.instance_variable_get(:@news_article)
    breadcrumbs = vc.instance_variable_get(:@breadcrumbs)
    raw(web_site.to_s) if web_site
    raw(news_media.to_s) if news_media
    raw(news_article.to_s) if news_article
    raw(breadcrumbs.to_s) if breadcrumbs
  end
end
