# frozen_string_literal: true

# rbs_inline: enabled

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # Provides default URL options for URL helpers in jobs.
  def default_url_options
    { host: "ruby-news.kr" }
  end

  rescue_from(StandardError) do |exception|
    honeybadger_context = {
      job: {
        class: self.class.name,
        arguments: arguments,
        queue_name: queue_name
      }
    }
    logger.error exception.backtrace if Rails.env.development?
    Honeybadger.notify(exception, error_class: exception.class.name, backtrace: exception.backtrace,
    error_message: exception.message, context: honeybadger_context)
  end
end
