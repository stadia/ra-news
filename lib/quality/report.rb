# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Quality
  class Report
    GateResult = Struct.new(:name, :measure, :threshold, :passed, :unit, :cmp, keyword_init: true)

    GATES = [
      { name: "Line coverage",       measure_path: [ :coverage, :line ],       threshold_path: [ "coverage", "line_min" ],       cmp: :>=, unit: "%" },
      { name: "Branch coverage",     measure_path: [ :coverage, :branch ],     threshold_path: [ "coverage", "branch_min" ],     cmp: :>=, unit: "%" },
      { name: "Flog max (method)",   measure_path: [ :flog, :method_max ],     threshold_path: [ "flog", "method_max" ],         cmp: :<=, unit: "" },
      { name: "Flog max (class)",    measure_path: [ :flog, :class_max ],      threshold_path: [ "flog", "class_max" ],          cmp: :<=, unit: "" }
    ].freeze

    # Reported, not gated. A hard floor here would either sit so far below the
    # current value that it never fires, or block PRs that merely add untyped
    # call sites in passing. Kept visible so the number moves deliberately
    # rather than drifting unnoticed.
    INFO_METRICS = [
      { name: "Type coverage (app)",  measure_path: [ :steep, :app, :percent ],  unit: "%" },
      { name: "Type coverage (test)", measure_path: [ :steep, :test, :percent ], unit: "%" }
    ].freeze

    def initialize(measurements:, thresholds:)
      @measurements = measurements
      @thresholds = thresholds
      @gate_results = build_gate_results
    end

    def passed?
      @gate_results.all?(&:passed)
    end

    def to_s
      lines = [ "Quality gates", "=============", "" ]
      @gate_results.each do |gate|
        status = gate.passed ? "✓" : "✗"
        lines << format(
          "%-25s %8s %s %8s    %s",
          gate.name,
          format_value(gate.measure, gate.unit),
          cmp_symbol(gate.cmp),
          format_value(gate.threshold, gate.unit),
          status
        )
      end
      lines << ""
      lines << "#{@gate_results.count(&:passed)}/#{@gate_results.size} gates passed."
      lines.concat(info_lines)
      lines.join("\n")
    end

    private

    def info_lines
      measured = INFO_METRICS.filter_map do |metric|
        value = dig_measurements(metric[:measure_path])
        [ metric, value ] unless value.nil?
      end
      return [] if measured.empty?

      lines = [ "", "Informational (not gated)", "-------------------------" ]
      measured.each do |metric, value|
        lines << format("%-25s %8s", metric[:name], format_value(value, metric[:unit]))
      end
      lines
    end

    def build_gate_results
      GATES.map do |gate_config|
        measure = dig_measurements(gate_config[:measure_path])
        threshold = dig_thresholds(gate_config[:threshold_path])
        passed = threshold.nil? || compare(measure, threshold, gate_config[:cmp])

        GateResult.new(
          name: gate_config[:name],
          measure: measure,
          threshold: threshold,
          passed: passed,
          unit: gate_config[:unit],
          cmp: gate_config[:cmp]
        )
      end
    end

    def dig_measurements(path)
      @measurements.dig(*path)
    end

    def dig_thresholds(path)
      @thresholds.dig(*path)
    end

    def compare(measure, threshold, cmp)
      return true if measure.nil? || threshold.nil?
      measure.public_send(cmp, threshold)
    end

    def format_value(value, unit)
      return "N/A" if value.nil?
      "#{value}#{unit}"
    end

    def cmp_symbol(cmp)
      { :>= => ">=", :<= => "<=" }[cmp]
    end
  end
end
