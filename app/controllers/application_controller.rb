# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

require "schema_dot_org/web_site"

class ApplicationController < ActionController::Base
  include LocaleSwitcher

  before_action :authenticate_user!
  allow_browser versions: { ie: false }
  application_layout = ->(controller) { controller.request.format.turbo_stream? ? false : Components::Layout } #: ^(ApplicationController) -> (singleton(Components::Layout) | false)
  layout application_layout

  before_action :set_web_site_schema

  unless Rails.env.production?
    around_action :n_plus_one_detection

    # `around_action` hands the rest of the request cycle in as a block, which
    # nothing in the source declared -- the annotation is what lets the bare
    # `yield` below type check. The `(&)` is required: Sorbet rejects a block
    # in the signature when the `def` has no block parameter (srb.help/3552).
    #: () { () -> void } -> void
    def n_plus_one_detection(&)
      Prosopite.scan
      yield
    ensure
      Prosopite.finish
    end
  end

  private

  def set_web_site_schema
    return unless request.path == "/"

    base = request.base_url
    @web_site = SchemaDotOrg::WebSite.new(
      name: t("layout.site_name"),
      url: base,
      potential_action: SchemaDotOrg::SearchAction.new(
        target: "#{base}/articles?search={search_term_string}",
        query_input: "required name=search_term_string"
      )
    )
  end

  def cacheable_page!(max_age: 5.minutes)
    return if user_signed_in?
    request.session_options[:skip] = true
    expires_in max_age, public: true
  end
end
