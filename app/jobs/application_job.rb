# frozen_string_literal: true
# rbs_inline: enabled

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Retry on connection errors with exponential backoff
  retry_on ActiveRecord::ConnectionNotEstablished, wait: :exponentially_longer, attempts: 5

  # Discard jobs for missing records
  discard_on ActiveJob::DeserializationError
  discard_on ActiveRecord::RecordNotFound

  # Provides default URL options for URL helpers in jobs.
  def default_url_options
    Rails.application.routes.default_url_options
  end

  rescue_from(StandardError) do |exception|
    # Log error details
    logger.error "Job failed: #{self.class.name} with arguments: #{arguments}"
    logger.error "Error: #{exception.class.name} - #{exception.message}"
    logger.error exception.backtrace.join("\n") if Rails.env.development?

    # Re-raise for proper job failure handling
    raise exception
  end
end
