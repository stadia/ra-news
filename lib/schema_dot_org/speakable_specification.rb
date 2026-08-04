# typed: strong
# frozen_string_literal: true
# rbs_inline: enabled

require "schema_dot_org"

module SchemaDotOrg
  ##
  # Model the Schema.org `Thing > Intangible > SpeakableSpecification`.
  # @see https://schema.org/SpeakableSpecification
  #
  # Indicates which parts of a NewsArticle are suitable for text-to-speech
  # (voice assistants). At least one of cssSelector or xpath must be present.
  # cssSelector serializes as `cssSelector` via the gem's
  # snake_case → lowerCamelCase conversion.
  #
  class SpeakableSpecification < SchemaType
    validated_attr :css_selector, type: union(String, [ String ]), allow_nil: true
    validated_attr :xpath,        type: union(String, [ String ]), allow_nil: true
  end
end
