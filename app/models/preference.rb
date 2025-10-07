# frozen_string_literal: true

# rbs_inline: enabled

class Preference < ApplicationRecord
  after_initialize :define_dynamic_accessors, if: -> { persisted? && name.present? }

  after_save do
    Rails.cache.delete(name)
  end

  def value=(val)
    super(val.is_a?(String) ? JSON.parse(val) : val)
  rescue JSON::ParserError
    super({})
  end

  #: (String name) -> Hash[String, untyped] || Array[untyped]
  def self.get_value(name)
    Rails.cache.fetch(name) {
      Preference.find_by(name:)&.value
    }
  end

  def self.ignore_hosts #: Array[String]
    get_value("ignore_hosts")
  end

  private

  def define_dynamic_accessors
    # This is an example configuration.
    # You should adjust this case statement to your needs.
    accessors = case name
    when "ignore_hosts" # Example name
                  [ :hosts ]
    # Add other cases for other preference names
    when /_oauth$/
      # Common keys for OAuth preferences
      [ :site, :client_id, :client_secret, :access_token, :refresh_token, :expires_at, :token_created_at ]
    else
                  []
    end

    accessors.each do |key|
      # Define getter
      define_singleton_method(key) do
        value.is_a?(Hash) ? value&.[](key.to_s) : value
      end

      # Define setter
      define_singleton_method("#{key}=") do |new_value|
        self.value = value.is_a?(Hash) ? (value || {}).merge(key.to_s => new_value) : value
      end
    end
  end
end
