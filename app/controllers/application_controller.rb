# frozen_string_literal: true
# rbs_inline: enabled

require "schema_dot_org/web_site"

class ApplicationController < ActionController::Base
  include LocaleSwitcher

  before_action :authenticate_user!
  allow_browser versions: { ie: false }
  layout -> { request.format.turbo_stream? ? false : Components::Layout }

  before_action do
    if request.path == "/"
      base = request.base_url
      @web_site = SchemaDotOrg::WebSite.new(
        name: "Ruby-News | 루비 AI 뉴스",
        url:  base,
        potential_action: SchemaDotOrg::SearchAction.new(
          target: "#{base}/articles?search={search_term_string}",
          query_input: "required name=search_term_string"
        )
      )
    end
  end

  unless Rails.env.production?
    around_action :n_plus_one_detection

    def n_plus_one_detection
      Prosopite.scan
      yield
    ensure
      Prosopite.finish
    end
  end

  private

  def cacheable_page!(max_age: 5.minutes)
    return if user_signed_in?
    request.session_options[:skip] = true
    expires_in max_age, public: true
  end
end
