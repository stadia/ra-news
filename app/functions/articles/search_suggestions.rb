# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module SearchSuggestions
    module_function

    # pg_bigm similarity를 활용해 검색 결과가 적을 때 유사 검색어를 제안한다.
    # pg_search_documents.content 컬럼에서 % 연산자로 유사도 기반 매칭.
    #: (String query, ?limit: Integer) -> Array[String]
    def suggest(query, limit: 5)
      return [] if query.blank?

      Article.joins(:pg_search_document)
             .kept.confirmed
             .where("pg_search_documents.content % ?", query)
             .order(Arel.sql(similarity_order(query)))
             .limit(limit)
             .pluck(:title_ko, :title)
             .flatten
             .compact
             .uniq
             .first(limit)
    rescue ActiveRecord::StatementInvalid
      # pg_bigm 확장이 설치되지 않은 환경에서는 빈 배열 반환
      []
    end

    #: (String query) -> String
    def similarity_order(query)
      quoted = Article.connection.quote(query)
      "similarity(pg_search_documents.content, #{quoted}) DESC"
    end
  end
end
