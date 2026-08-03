# frozen_string_literal: true
# rbs_inline: enabled

require "csv"

module Quality
  # `steep check` passing means "no contradiction found", not "the code is
  # typed" -- calls whose receiver resolves to `untyped` are skipped silently.
  # `steep stats` counts them, which is the only way to see that gap move.
  class SteepStatsParser
    # steep prefixes the CSV with a progress line and a blank line, so the
    # header is not on row 1 and the file cannot be handed to CSV.read as-is.
    HEADER_PREFIX = "Target,File,"

    #: (untyped csv_path) -> void
    def initialize(csv_path)
      @csv_path = csv_path
    end

    #: () -> Hash[Symbol, untyped]
    def parse
      rows = read_rows
      return {} if rows.empty?

      rows
        .group_by { |row| row["Target"] }
        .to_h { |target, target_rows| [ target.to_sym, summarize(target_rows) ] }
    end

    private

    #: () -> Array[untyped]
    def read_rows
      lines = File.readlines(@csv_path)
      header_index = lines.index { |line| line.start_with?(HEADER_PREFIX) }
      return [] if header_index.nil?

      # `.map(&:to_h)`, not `.to_a`: CSV::Table#to_a returns the header array
      # followed by plain value arrays, which do not respond to `row["Target"]`.
      CSV.parse(lines[header_index..].join, headers: true).map(&:to_h)
    end

    #: (Array[untyped] rows) -> Hash[Symbol, untyped]
    def summarize(rows)
      typed = sum(rows, "Typed calls")
      untyped = sum(rows, "Untyped calls")
      all = sum(rows, "All calls")

      {
        files: rows.size,
        typed: typed,
        untyped: untyped,
        all: all,
        # Guard against a target with no call sites at all -- an empty `check`
        # glob would otherwise divide by zero.
        percent: all.zero? ? 0.0 : (100.0 * typed / all).round(1)
      }
    end

    #: (Array[untyped] rows, String column) -> Integer
    def sum(rows, column)
      rows.sum { |row| row[column].to_i }
    end
  end
end
