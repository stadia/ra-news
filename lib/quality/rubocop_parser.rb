# frozen_string_literal: true
# rbs_inline: enabled

require "json"

module Quality
  class RubocopParser
    COPS = {
      class_length_max: "Metrics/ClassLength",
      module_length_max: "Metrics/ModuleLength",
      method_length_max: "Metrics/MethodLength",
      abc_size_max: "Metrics/AbcSize",
      cyclomatic_complexity_max: "Metrics/CyclomaticComplexity",
      perceived_complexity_max: "Metrics/PerceivedComplexity"
    }.freeze

    # Captures the first "<measured>/<max>" pair in the offense message.
    # Handles "[143/100]" and "[<7, 18, 3> 19.55/15]" shapes.
    MEASURE_RE = %r{\[<?[\d,\s]*>?\s*([\d.]+)/[\d.]+\]}

    def initialize(path)
      @path = path
    end

    def parse
      data = JSON.parse(File.read(@path))
      offenses = data.fetch("files").flat_map { |f| f["offenses"] }
      COPS.transform_values { |cop_name| max_for(cop_name, offenses) }
    end

    private

    def max_for(cop_name, offenses)
      values = offenses
        .select { |o| o["cop_name"] == cop_name }
        .map { |o| o["message"][MEASURE_RE, 1]&.to_f }
        .compact

      return nil if values.empty?

      picked = values.max
      picked == picked.to_i ? picked.to_i : picked
    end
  end
end
