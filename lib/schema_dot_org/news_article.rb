# typed: strong
# frozen_string_literal: true
# rbs_inline: enabled

require "schema_dot_org"
require "schema_dot_org/organization"
require "schema_dot_org/person"
require "schema_dot_org/speakable_specification"
require "schema_dot_org/creative_work"

module SchemaDotOrg
  ##
  # Model the Schema.org `Thing > CreativeWork > Article > NewsArticle`.
  # @see https://schema.org/NewsArticle
  #
  # Google's required properties for NewsArticle rich results:
  #   headline, image (optional but recommended), datePublished, author
  #
  # Usage in controller:
  #   @news_article = SchemaDotOrg::NewsArticle.new(
  #     headline:       article.title_ko,
  #     description:    article.summary_key&.first,
  #     url:            article_url(article.slug),
  #     date_published: article.published_at&.iso8601,
  #     date_modified:  article.updated_at.iso8601,
  #     in_language:    "ko-KR",
  #     is_based_on:    article.url,
  #     publisher:      SchemaDotOrg::Organization.new(
  #                       name: "Ruby-News",
  #                       url:  "https://ruby-news.dev",
  #                       logo: "https://ruby-news.dev/icon.png"
  #                     )
  #   )
  #
  # Usage in view:
  #   <%= @news_article %>
  #
  class NewsArticle < SchemaType
    ##
    # Optional attributes
    ##
    validated_attr :author,         type: union(Organization, Person), allow_nil: true
    validated_attr :date_modified,  type: String,                      allow_nil: true
    validated_attr :description,    type: String,                      allow_nil: true
    validated_attr :image,          type: String,                      allow_nil: true
    validated_attr :in_language,    type: String,                      allow_nil: true
    # isBasedOn accepts CreativeWork, Product, or URL (schema.org/URL = plain String)
    validated_attr :is_based_on,    type: String,                      allow_nil: true
    validated_attr :keywords,       type: union(String, [ String ]),     allow_nil: true
    # speakable: SpeakableSpecification → JSON key `speakable`
    validated_attr :speakable,      type: SpeakableSpecification,        allow_nil: true
    # translationOfWork: 원문(번역 출처). schema.org 범위가 CreativeWork 이므로
    # 원문 URL 을 가진 CreativeWork 객체로 모델링한다 (plain String 금지).
    validated_attr :translation_of_work, type: CreativeWork,             allow_nil: true

    ##
    # Required by Google for NewsArticle rich results
    ##
    validated_attr :date_published, type: String,       presence: true
    validated_attr :headline,       type: String,       presence: true
    validated_attr :publisher,      type: Organization
    validated_attr :url,            type: String,       presence: true
  end
end
