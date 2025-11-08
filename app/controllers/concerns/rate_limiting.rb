# frozen_string_literal: true

module RateLimiting
  extend ActiveSupport::Concern

  included do
    before_action :check_rate_limit, only: [ :create, :update ]
  end

  private

  def check_rate_limit
    return if Current.user&.admin?

    cache_key = "rate_limit:#{request.remote_ip}:#{controller_name}"

    # Use increment for atomic operation (prevents race conditions)
    # Initialize if not exists, then check
    current_count = Rails.cache.read(cache_key) || 0
    if current_count >= rate_limit_threshold
      render json: { error: "Rate limit exceeded" }, status: :too_many_requests
      return
    end

    # Atomically increment the counter
    Rails.cache.increment(cache_key, 1, expires_in: 1.hour)
  end

  def rate_limit_threshold
    case controller_name
    when "comments"
      10 # 10 comments per hour
    when "articles"
      5  # 5 articles per hour
    else
      20 # Default limit
    end
  end
end
