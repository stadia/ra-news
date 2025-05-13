class GmailClient
  attr_reader :conn

  def initialize(email = nil, password = nil)
    email ||= ENV["GMAIL_EMAIL"] || "stadia@gmail.com"
    password ||= ENV["GMAIL_PASSWORD"]

    @conn = Gmail.new(email, password)
    Rails.logger.debug "Gmail 클라이언트 초기화: #{email}"
  end

  def get_emails(from: nil, limit: 10)
    Rails.logger.debug "받은편지함 이메일 수: #{conn.inbox.count}"

    if from
      conn.inbox.emails(from: from).first(limit)
    else
      conn.inbox.emails.first(limit)
    end
  end

  def get_emails_by_label(label, limit: 10)
    Rails.logger.debug "#{label} 라벨 이메일 수: #{conn.mailbox(label).count}"
    conn.mailbox(label).emails.first(limit)
  end

  def search_emails(query, limit: 10)
    Rails.logger.debug "검색 쿼리: #{query}"
    conn.inbox.emails(search: query).first(limit)
  end

  def close
    conn.logout if conn
  end
end
