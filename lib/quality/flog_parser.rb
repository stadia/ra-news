# frozen_string_literal: true
# rbs_inline: enabled

require "flog"

module Quality
  class FlogParser
    EXCLUDE_PATTERNS = %w[
      app/components
      app/views
      app/components/**
      app/views/**
    ].freeze

    def initialize(paths)
      @paths = Array(paths).flat_map do |p|
        if File.directory?(p)
          Dir.glob(File.join(p, "**", "*.rb"))
        else
          p
        end
      end.reject { |f| f.include?("app/components/") || f.include?("app/views/") }
    end

    def parse
      flog = Flog.new
      flog.flog(*@paths)

      totals = flog.totals.reject { |name, _| name.end_with?("#none", ".none") }
      return { method_max: 0.0, class_max: 0.0 } if totals.empty?

      {
        method_max: totals.values.max,
        class_max: max_class_score(totals)
      }
    end

    private

    def max_class_score(totals)
      totals
        .group_by { |method_name, _| method_name.split(/[#.]/, 2).first }
        .values
        .map { |entries| entries.sum { |_, score| score } }
        .max
    end
  end
end
