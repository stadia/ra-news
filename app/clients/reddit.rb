# frozen_string_literal: true
# rbs_inline: enabled

module Reddit
  module_function

  BASE_URL = "https://www.reddit.com"
  SUBREDDIT = "ruby+rails"
  USER_AGENT = "ruby-news/1.0 (by /u/ruby-news-bot)"

  # Reddit JSON API를 사용해 게시물을 가져온다.
  #
  # sort: :hot, :new, :top, :rising, :controversial
  # period: :hour, :day, :week, :month, :year, :all (top/controversial에서만 사용)
  # limit: 1~100
  #
  #: (?sort: Symbol, ?period: Symbol, ?limit: Integer) -> Array[Hash[String, untyped]]
  def feed(sort: :top, period: :day, limit: 50)
    url = "#{BASE_URL}/r/#{SUBREDDIT}/#{sort}.json"

    response = Faraday.get(url) do |req|
      req.headers["User-Agent"] = USER_AGENT
      req.params["t"] = period.to_s if %i[top controversial].include?(sort)
      req.params["limit"] = limit
    end

    JSON.parse(response.body).dig("data", "children").map { |child| child["data"] }
  end
end
