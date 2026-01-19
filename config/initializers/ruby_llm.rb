# config/initializers/ruby_llm.rb or similar
RubyLLM.configure do |config|
  config.gemini_api_key = ENV.fetch("GEMINI_API_KEY", nil)
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)

  # --- Default Models ---
  # Used by RubyLLM.chat, RubyLLM.embed, RubyLLM.paint if no model is specified.
  config.default_model = "gemini-3-flash-preview"

  # --- Connection Settings ---
  config.request_timeout = 120  # Request timeout in seconds (default: 120)
  config.max_retries = 3        # Max retries on transient network errors (default: 3)
  config.retry_interval = 0.1 # Initial delay in seconds (default: 0.1)

  # config.ollama_api_base = "http://127.0.0.1:1234/v1"
  config.model_registry_file = "config/models.json"

  # --- OR Custom Logger ---
  config.logger = Rails.logger
end
