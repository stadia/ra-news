# frozen_string_literal: true

# rbs_inline: enabled

class HtmlContentTool < RubyLLM::Tool
  description "url을 통해 가져온 HTML 문서에서 주요 콘텐츠를 추출합니다."

  param :url, desc: "URL of the HTML document (e.g., https://example.com)"

  #: (url String) -> String?
  def execute(url:)
    response = Faraday.get(url)
    html_content = response.body
    return nil if html_content.blank?

    # Readability를 사용하여 주요 콘텐츠 HTML 추출. Readability::Document는 전체 HTML 문자열을 인자로 받습니다.
    Readability::Document.new(html_content).content
  end
end
