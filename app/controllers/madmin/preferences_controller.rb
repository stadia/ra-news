# typed: true
# rbs_inline: enabled

module Madmin
  class PreferencesController < Madmin::ResourceController
    private

    def resource_params
      params_hash = super
      record = @record || resource.model.new(name: params_hash[:name])
      record_methods = record.methods
      params_hash.delete_if { |key, _value| !record_methods.include?(key.to_sym) }
      params_hash
    end
  end
end
