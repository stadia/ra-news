# typed: strong
# frozen_string_literal: true
# rbs_inline: enabled

require "schema_dot_org"
require "schema_dot_org/organization"

module SchemaDotOrg
  ##
  # Model the Schema.org `Thing > Organization > NewsMediaOrganization`.
  # @see https://schema.org/NewsMediaOrganization
  #
  # NewsMediaOrganization is a subtype of Organization designed for news
  # publishers and aggregators. Google uses it as a prerequisite signal
  # for Top Stories and publisher trust verification.
  #
  class NewsMediaOrganization < Organization
    validated_attr :masthead, type: String, allow_nil: true
  end
end
