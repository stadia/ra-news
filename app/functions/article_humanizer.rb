# typed: strict
# frozen_string_literal: true
# rbs_inline: enabled

module ArticleHumanizer
  extend FunctionLogger

  class << self
    #: (Article article) -> String
    def prompt(article)
      keys = Array(article.summary_key).map(&:to_s).reject(&:blank?)
      details = article.summary_detail.to_h.transform_values(&:to_s)
      body = article.summary_body.to_s

      payload = {
        summary_key: keys,
        summary_detail: details,
        summary_body: body
      }

      <<~PROMPT
        다음 JSON의 각 필드를 사람이 쓴 것처럼 윤문하여 동일한 구조로 반환하라.
        #{JSON.pretty_generate(payload)}
      PROMPT
    end
  end
end
