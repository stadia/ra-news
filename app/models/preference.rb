# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class Preference < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  after_initialize :define_dynamic_accessors, if: -> { name.present? }

  after_commit :clear_cache, on: %i[create update destroy]

  #: (String? value) -> String?
  def name=(value)
    super.tap do
      define_dynamic_accessors if name.present?
    end
  end

  #: (String name) -> (Hash[String, untyped] | Array[untyped])?
  def self.get_value(name)
    get_object(name)&.value
  end

  #: (String name) -> Preference?
  def self.get_object(name)
    resolving = Thread.current[:preference_resolving] ||= Set.new
    return nil if resolving.include?(name)

    resolving.add(name)
    Rails.cache.fetch("preferences_#{name}", expires_in: 1.hour, skip_nil: true) do
      Preference.find_by(name:)
    end
  ensure
    resolving&.delete(name)
  end

  #: () -> Array[String]
  def self.ignore_hosts
    value = get_value("ignore_hosts")
    value.is_a?(Array) ? value.grep(String) : []
  end

  #: () -> void
  def clear_cache
    Rails.cache.delete("preferences_#{name}")
  end

  private

  #: () -> void
  def define_dynamic_accessors
    # This is an example configuration.
    # You should adjust this case statement to your needs.
    accessors = case name
    when "ignore_hosts" # Example name
      [ :hosts ]
    # Add other cases for other preference names
    when /_oauth$/
      # Common keys for OAuth preferences
      [ :site, :client_id, :client_secret, :signing_secret, :access_token, :refresh_token, :expires_at, :token_created_at, :team_id, :key_id ]
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
        case key
        when :hosts
          self.value = new_value.split(" ")
        else
          hash = value.is_a?(Hash) ? value : {}
          self.value = hash.merge(key.to_s => new_value)
        end
      end
    end
  end
end
