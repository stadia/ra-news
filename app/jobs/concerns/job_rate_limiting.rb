# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

module JobRateLimiting
  extend ActiveSupport::Concern

  private

  # Returns true if under the rate limit (and increments the counter),
  # false if the limit has already been reached for the current window.
  #: () -> bool
  def check_rate_limit
    cache_key = "rate_limit:#{self.class.name}"
    current_count = Rails.cache.read(cache_key).to_i

    if current_count >= rate_limit_threshold
      logger.warn("Rate limit reached for #{self.class.name}: #{current_count}/#{rate_limit_threshold} per #{rate_limit_window.inspect}")
      return false
    end

    Rails.cache.write(cache_key, current_count + 1, expires_in: rate_limit_window)
    true
  end

  # Override in each job to define the maximum number of items processed per window.
  #: () -> Integer
  def rate_limit_threshold
    raise NotImplementedError, "#{self.class.name} must implement #rate_limit_threshold"
  end

  # Override in each job to define the time window for rate limiting.
  # Defaults to 1 hour. Use 1.minute for per-minute control, etc.
  #: () -> ActiveSupport::Duration
  def rate_limit_window
    1.hour
  end
end
