# frozen_string_literal: true

module Types
  class ArticleFeedKindEnum < Types::BaseEnum
    graphql_name "ArticleFeedKind"

    value "RELATED", "Related articles feed"
    value "OTHERS", "Other articles feed"
    value "TAGGED", "Articles tagged with a keyword"
  end
end
