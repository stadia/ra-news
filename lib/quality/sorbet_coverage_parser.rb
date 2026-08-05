# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

require "json"

module Quality
  # `srb tc` passing means "no contradiction found in the files Sorbet was
  # allowed to look at", not "the code is typed". A `# typed: false` file is
  # checked for syntax and RBI drift only -- its signatures, including the
  # inline `#:` RBS comments, are ignored outright. So the number worth
  # watching is not the error count (it is gated at zero) but how much of the
  # codebase sits above that floor.
  #
  # Reads the JSON that `Spoom::Coverage::Snapshot#to_json` produces. The
  # `_excluding_rbis` variants are the ones that matter: the plain `sigils`
  # count includes the ~950 committed files under `sorbet/rbi`, which are
  # generated, always `typed: true`, and would drown the app's own ratio.
  #
  # Replaced SteepStatsParser when Steep was dropped on 2026-08-05. Steep
  # measured typed-vs-untyped *call sites*; there is no equivalent figure in
  # Sorbet's metrics, so the sigil ratio takes its place as the coverage
  # headline.
  class SorbetCoverageParser
    #: (untyped json_path) -> void
    def initialize(json_path)
      @json_path = json_path
    end

    #: () -> Hash[Symbol, untyped]
    def parse
      snapshot = read_snapshot
      return {} if snapshot.empty?

      {
        sigils: summarize_sigils(snapshot.fetch("sigils_excluding_rbis", {})),
        methods: summarize_methods(snapshot)
      }
    end

    private

    #: () -> Hash[String, untyped]
    def read_snapshot
      return {} unless File.exist?(@json_path)

      parsed = JSON.parse(File.read(@json_path))
      parsed.is_a?(Hash) ? parsed : {}
    rescue JSON::ParserError
      # The rake task runs spoom with `|| true`, so a crashed run leaves a
      # truncated or empty file behind. Treat that as "not measured" and let
      # the task warn, rather than taking the whole quality run down.
      {}
    end

    #: (Hash[String, untyped] sigils) -> Hash[Symbol, untyped]
    def summarize_sigils(sigils)
      # `strict`/`strong` are counted as typed: they are levels above `true`,
      # not a separate category. `ignore` is excluded from the denominator --
      # those files are not candidates for being typed at all.
      typed = sigils.fetch("true", 0) + sigils.fetch("strict", 0) + sigils.fetch("strong", 0)
      untyped = sigils.fetch("false", 0)
      all = typed + untyped

      { typed: typed, untyped: untyped, all: all, percent: percent(typed, all) }
    end

    #: (Hash[String, untyped] snapshot) -> Hash[Symbol, untyped]
    def summarize_methods(snapshot)
      with_sig = snapshot.fetch("methods_with_sig_excluding_rbis", 0)
      without_sig = snapshot.fetch("methods_without_sig_excluding_rbis", 0)
      all = with_sig + without_sig

      { with_sig: with_sig, without_sig: without_sig, all: all, percent: percent(with_sig, all) }
    end

    #: (Integer part, Integer total) -> Float
    def percent(part, total)
      return 0.0 if total.zero?

      # `.to_f`: Sorbet types `Float#round(ndigits)` as `T.any(Integer, Float)`
      # because the zero-digit overload narrows to `Integer`. It cannot tell
      # from the literal `1` which arm applies, so pin the result here rather
      # than widening the signature.
      (100.0 * part / total).round(1).to_f
    end
  end
end
