# typed: true
# frozen_string_literal: true

class Components::Layout::StructuredData < Components::Base
  def view_template
    render_schema_org
  end

  private

  def render_schema_org
    assigns = view_context.assigns
    web_site = assigns["web_site"]
    news_media = assigns["news_media_organization"]
    news_article = assigns["news_article"]
    breadcrumbs = assigns["breadcrumbs"]
    raw(web_site.to_s) if web_site
    raw(news_media.to_s) if news_media
    raw(news_article.to_s) if news_article
    raw(breadcrumbs.to_s) if breadcrumbs
  end
end
