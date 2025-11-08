# frozen_string_literal: true

# rbs_inline: enabled

class Preference < ApplicationRecord
  PROTECTED_KEYS = %w[name value]

  after_initialize :prepare_hash_accessor, if: -> { persisted? && name.present? }

  after_commit :clear_cache, on: %i[create update destroy]

  #: (String name) -> Hash[String, untyped] || Array[untyped]
  def self.get_value(name)
    get_object(name)&.value
  end

  def self.get_object(name)
    Rails.cache.fetch("preferences_#{name}", expires_in: 2.weeks) do
      Preference.find_by(name:)
    end
  end

  def self.ignore_hosts #: Array[String]
    get_value("ignore_hosts") || []
  end

  def clear_cache
    Rails.cache.delete("preferences_#{name}")
  end

  # Safe hash access for preference values
  #: (String key) -> untyped
  def get(key)
    return value.is_a?(Hash) ? value[key.to_s] : nil
  end

  # Safe hash setter for preference values
  #: (String key, untyped val) -> untyped
  def set(key, val)
    self.value = if value.is_a?(Hash)
                   (value || {}).merge(key.to_s => val)
                 else
                   { key.to_s => val }
                 end
    val
  end

  private

  def prepare_hash_accessor
    # Ensures value is a Hash if needed based on preference name
    return unless value.is_a?(Hash) || %w[ignore_hosts].any? { |n| name.match?(n) } || name.match?(/_oauth$/)

    # Initialize empty hash if value is nil
    self.value ||= {} if name.match?(/_oauth$/)
  end
end
