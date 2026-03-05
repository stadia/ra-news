# frozen_string_literal: true

# rbs_inline: enabled

require "schema_dot_org/web_site"

class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: { ie: false }

  before_action do
    Honeybadger.context({
      user_id: Current.user&.id
    })
    @web_site = SchemaDotOrg::WebSite.new(
      name: " Ruby-News || 루비 AI 뉴스",
      url:  "https://ruby-news.kr",
      potential_action: SchemaDotOrg::SearchAction.new(
        target: "https://ruby-news.kr/articles?search={search_term_string}",
        query_input: "required name=search_term_string"
      )
    )
  end
end
