# frozen_string_literal: true

require "json"

module Quality
  module CoverageSnapshot
    PARTIAL_RUN_OPTIONS = %w[-n --name -i --include -e --exclude].freeze
    OPTIONS_WITH_VALUES = %w[-n --name -i --include -e --exclude --seed].freeze

    module_function

    def full_suite_run?(argv = ARGV, root = Rails.root)
      return false if argv.any? { |arg| partial_run_option?(arg) }

      test_targets = positional_test_targets(argv)
      return true if test_targets.empty?

      expanded_targets = expand_test_targets(test_targets, root)
      return false if expanded_targets.empty?

      expanded_targets.sort == all_test_files(root)
    end

    def preferred_path(root = Rails.root)
      snapshot = snapshot_path(root)
      snapshot.exist? ? snapshot : default_path(root)
    end

    def persist_result!(result, root = Rails.root)
      File.write(snapshot_path(root), JSON.pretty_generate(snapshot_payload(result)))
    end

    def snapshot_path(root = Rails.root)
      root.join("coverage/.quality_last_run.json")
    end

    def snapshot_payload(result)
      {
        result: {
          line: result.covered_percent.round(2),
          branch: result.coverage_statistics.fetch(:branch).percent.round(2)
        }
      }
    end

    def default_path(root = Rails.root)
      root.join("coverage/.last_run.json")
    end

    def partial_run_option?(arg)
      PARTIAL_RUN_OPTIONS.include?(arg) || PARTIAL_RUN_OPTIONS.any? { |option| arg.start_with?("#{option}=") }
    end

    def positional_test_targets(argv)
      argv.each_with_object([]).with_index do |(arg, targets), index|
        previous = index.positive? ? argv[index - 1] : nil
        next if previous && OPTIONS_WITH_VALUES.include?(previous)
        next if arg.start_with?("-")
        next if OPTIONS_WITH_VALUES.any? { |option| arg.start_with?("#{option}=") }

        targets << arg
      end
    end

    def expand_test_targets(targets, root)
      targets.flat_map do |target|
        normalized_target = target.split(":").first
        absolute_path = root.join(normalized_target)

        if absolute_path.directory?
          Dir[absolute_path.join("**/*_test.rb")]
        elsif absolute_path.file?
          [ absolute_path.to_s ]
        else
          []
        end
      end.uniq
    end

    def all_test_files(root)
      Dir[root.join("test/**/*_test.rb")].sort
    end
  end
end
