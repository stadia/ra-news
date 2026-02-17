# frozen_string_literal: true

class Components::Articles::ArticleUser < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(article:)
    @article = article
  end

  def view_template
    if @article.user
      plain @article.user.name
    elsif @article.site
      if @article.site.base_uri.present?
        link_to(@article.site.name, @article.site.base_uri, target: "_blank")
      else
        plain @article.site.name
      end
    else
      span(class: "text-gray-500") { "알 수 없음" }
    end
  end
end
