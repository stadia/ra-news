# config/initializers/ruby_llm.rb or similar
RubyLLM.configure do |config|
  config.gemini_api_key = Rails.application.credentials["GEMINI_API_KEY"]

  # --- Default Models ---
  # Used by RubyLLM.chat, RubyLLM.embed, RubyLLM.paint if no model is specified.
  config.default_model = "gemini-2.0-flash"

  # --- Connection Settings ---
  config.request_timeout = 120  # Request timeout in seconds (default: 120)
  config.max_retries = 3        # Max retries on transient network errors (default: 3)
  config.retry_interval = 0.1 # Initial delay in seconds (default: 0.1)
end
