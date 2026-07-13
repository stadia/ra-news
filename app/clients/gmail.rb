# frozen_string_literal: true
# rbs_inline: enabled

require "timeout"

class Gmail
  # Constants for default email and imap
  DEFAULT_IMAP_ADDRESS = "imap.gmail.com"
  DEFAULT_GMAIL_ADDRESS = "admin@example.com"
  # mail gem은 Net::IMAP.new를 위치 인자로 하드코딩해 타임아웃 주입 훅이 없으므로
  # Faraday 표준 패턴 대신 실제 IMAP 조회를 Timeout.timeout으로 감싼다.
  # 주의: Timeout.timeout은 임의 지점에서 스레드를 인터럽트해 소켓을 정리하지 못할 수
  # 있으나, gem이 소켓 레벨 타임아웃 훅을 주지 않아 차선책으로 사용한다.
  # 15초 = open(5)+read(10)에 대응하는 단일 wall-clock 예산(open/read 구분 불가).
  NETWORK_TIMEOUT = 15 #: Integer

  def initialize #: Gmail
    password = ENV["MAIL_PASSWORD"]

    Mail.defaults do
      retriever_method :imap, address: ENV["IMAP_ADDRESS"] || DEFAULT_IMAP_ADDRESS,
                              port: 993,
                              user_name: ENV["MAIL_ADDRESS"] || DEFAULT_GMAIL_ADDRESS,
                              password: password,
                              enable_ssl: true
    end
  end

  def fetch_emails(options = {})
    sender = options[:from] || "rubyonrails@maily.so"
    since_date = options[:since] || 1.month.ago

    # IMAP 검색 쿼리를 명시적으로 구성
    query = "FROM \"#{sender}\""
    # 날짜 필터링 추가
    if since_date
      # IMAP 날짜 형식으로 변환 (DD-MMM-YYYY)
      formatted_date = since_date.strftime("%d-%b-%Y")
      query += " SINCE \"#{formatted_date}\""
    end
    logger.debug "IMAP 검색 쿼리: #{query}"

    emails = Timeout.timeout(NETWORK_TIMEOUT) { Mail.find(order: :desc, keys: query) }
    logger.info "검색된 이메일 수: #{emails.length}"
    emails
  end

  def fetch_email_links(options = {})
    links = []
    fetch_emails(options)&.each do |body|
      html_content = nil
      if body.multipart?
        # HTML 부분 찾기
        html_part = body.parts.find { |p| p.mime_type == "text/html" }
        if html_part
          # 인코딩 처리를 포함한 디코딩
          html_content = html_part.body.decoded.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
        end
      elsif body.mime_type == "text/html"
        # 멀티파트가 아닌 경우 직접 확인
        html_content = body.body.decoded.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
      end
      # 특수 문자 및 인코딩 문제 해결
      html_content = html_content.gsub(/[\r\n]+/, " ") # 줄바꿈 제거
                                  .gsub(/=\r?\n/, "") # quoted-printable 줄바꿈 제거
      # logger.debug html_content
      next unless html_content

      # Nokogiri로 파싱
      html_doc = Nokogiri::HTML5(html_content)

      # 링크 추출
      html_doc.css("a[href]").each {
        next if it["href"].blank?
        links << it["href"] if it["href"].is_a?(String)
      }
    end
    links.uniq
  end

  private

  def logger
    Rails.logger
  end
end
