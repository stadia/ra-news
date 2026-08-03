# frozen_string_literal: true
# rbs_inline: enabled

require "schema_dot_org"

module SchemaDotOrg
  ##
  # Model the Schema.org `Thing > CreativeWork`.
  # @see https://schema.org/CreativeWork
  #
  # 최소 형태로, 다른 저작물(원문 등)을 URL 로 참조할 때 사용한다.
  # 예: NewsArticle#translationOfWork 는 schema.org 상 CreativeWork 범위를
  # 요구하므로 원문 URL 을 가진 CreativeWork 객체로 표현한다.
  #
  class CreativeWork < SchemaType
    validated_attr :url,      type: String, allow_nil: true
    validated_attr :name,     type: String, allow_nil: true
    validated_attr :headline, type: String, allow_nil: true
  end
end
