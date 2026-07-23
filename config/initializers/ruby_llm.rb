# config/initializers/ruby_llm.rb or similar
RubyLLM.configure do |config|
  # --- Default Models ---
  # Used by RubyLLM.chat, RubyLLM.embed, RubyLLM.paint if no model is specified.
  config.default_model = "gemini-3-flash-preview"
  # config.gemini_api_base = 'https://generativelanguage.googleapis.com/v1'

  # --- Connection Settings ---
  config.request_timeout = 120  # Request timeout in seconds (default: 120)
  config.max_retries = 3        # Max retries on transient network errors (default: 3)
  config.retry_interval = 0.1 # Initial delay in seconds (default: 0.1)

  # config.ollama_api_base = "http://127.0.0.1:1234/v1"
  config.model_registry_file = "config/models.json"

  # --- OR Custom Logger ---
  config.logger = Rails.logger

  config.gemini_api_key = ENV.fetch("GEMINI_API_KEY", nil)

  # API key - use what your server expects
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)
  config.openai_api_base = ENV.fetch("OPENAI_API_BASE", "https://api.openai.com/v1/")

  config.openrouter_api_key = ENV.fetch("OPENROUTER_API_KEY", nil)

  config.ollama_api_base = ENV.fetch("OLLAMA_API_BASE", "https://ollama.com/v1/")
  config.ollama_api_key = ENV.fetch("OLLAMA_API_KEY", nil)
end
