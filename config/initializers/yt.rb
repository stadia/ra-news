# rbs_inline: enabled

Yt.configure do |config|
  config.api_key = ENV["YOUTUBE_API_KEY"]
  config.log_level = Rails.logger.level
end
