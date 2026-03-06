# frozen_string_literal: true

require "schema_dot_org"

module SchemaDotOrg
  ##
  # Model the Schema.org `Thing > CreativeWork > WebPage`.
  # Used primarily as the +isBasedOn+ value in NewsArticle to point to the
  # original English source URL.
  # @see https://schema.org/WebPage
  #
  class WebPage < SchemaType
    validated_attr :url, type: String, presence: true
  end
end
