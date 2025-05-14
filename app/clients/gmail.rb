# frozen_string_literal: true

# rbs_inline: enabled

class Gmail
  def initialize
    email ||= ENV["GMAIL_ADDRESS"] || "stadia@gmail.com"
    password ||= ENV["GMAIL_PASSWORD"]

    Mail.defaults do
      retriever_method :imap, address: "imap.gmail.com",
                              port: 993,
                              user_name: email,
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
    Rails.logger.debug "IMAP 검색 쿼리: #{query}"

    emails = Mail.find(order: :desc, keys: query)
    Rails.logger.info "검색된 이메일 수: #{emails.length}"
    emails
  end

  IGNORE_HOSTS = [ "www.meetup.com", "maily.so", "github.com", "bsky.app", "threadreaderapp.com", "x.com",
  "www.linkedin.com", "meet.google.com", "www.twitch.tv", "inf.run", "lu.ma" ]

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
      html_content = html_content.gsub(/[\r\n]+/, " ")  # 줄바꿈 제거
                                  .gsub(/=\r?\n/, "")    # quoted-printable 줄바꿈 제거
      Rails.logger.debug html_content
      next unless html_content

      # Nokogiri로 파싱
      html_doc = Nokogiri::HTML5(html_content)
      # 링크 추출
      html_doc.css("a[href]").each {
        uri = URI.parse(it["href"])
        links << case uri.host
        when "maily.so"
          # URI 객체가 query를 지원하는지 확인 (예: URI::HTTP, URI::HTTPS)
          if uri.respond_to?(:query) && uri.query
            # 쿼리 문자열을 해시(맵)으로 변환
            query_params = URI.decode_www_form(uri.query).to_h
            if query_params["url"].is_a?(String)
              url = URI.parse(query_params["url"])
              next if IGNORE_HOSTS.include?(url.host) || url.path.size < 2

              url
            end
          end
        else
                   uri
        end
      }
    end
    links.uniq
  end
end
