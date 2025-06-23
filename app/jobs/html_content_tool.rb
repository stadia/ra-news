# frozen_string_literal: true

# rbs_inline: enabled

class HtmlContentTool < RubyLLM::Tool
  description "url을 통해 가져온 HTML 문서에서 주요 콘텐츠를 추출합니다."

  param :url, desc: "URL of the HTML document (e.g., https://example.com)"

  #: (url String) -> String?
  def execute(url:)
    html_content = handle_redirection(url).body
    return nil if html_content.blank?

    # Readability를 사용하여 주요 콘텐츠 HTML 추출. Readability::Document는 전체 HTML 문자열을 인자로 받습니다.
    Readability::Document.new(html_content).content
  end

  private

  def handle_redirection(url, count = 0)
    response = Faraday.get(url)
    return response unless response.status.between?(300, 399) && response.headers["location"]
    return response if count > 3

    Rails.logger.debug response.headers["location"]
    # 3xx 응답인 경우 리다이렉트된 URL을 사용
    redirect_url = response.headers["location"]
    url = if redirect_url.start_with?("http")
                 redirect_url
               else
                 URI.join(url, redirect_url).to_s
               end

    handle_redirection(url, count + 1)
  end
end
