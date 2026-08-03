# frozen_string_literal: true
# rbs_inline: disabled

# Steep type-checking entry points.
#
# Steep 2.0 additions in use here:
#   * `steep server` -- daemon that keeps the RBS environment loaded in memory,
#     so repeated `steep check` runs skip the slow environment reload. Useful
#     while bumping files from `# typed: false` to `# typed: true`, which is
#     many iterative checks.
#   * `steep check -e "EXPR"` -- type-check a one-liner from the CLI without
#     editing files, e.g. `bundle exec steep check -e "Like.for_actor(nil)"`.
#
# Pipeline (see .github/workflows/ci.yml): Steep reads `sig/generated/*.rbs`
# produced by `rbs-inline`, NOT the inline `#:` comments those files are
# generated from. After editing a `#:` annotation, run `rake steep:regenerate`
# and commit the changed `sig/generated/` so the two stay in sync -- CI rejects
# drift between them.
#
# `inline: true` is intentionally NOT enabled. Native inline RBS in Steep 2.0
# is experimental, omits `class << self`, and does not yet reproduce the broad
# body type-checking the generated signatures provide; enabling it alongside
# the pipeline yields ~100 DuplicatedDeclaration errors from the duplicate
# declarations. Keep the rbs-inline generation until native inline matures and
# the `class << self` (and similar) gaps are filled.

namespace :steep do
  desc "Type-check with Steep (faster if `steep:server:start` is running)"
  task :check do
    sh "bundle exec steep check"
  end

  desc "Regenerate sig/generated from inline `#:` annotations (run after editing them)"
  task :regenerate do
    sh "bundle exec rbs-inline --output app lib"
  end

  namespace :server do
    desc "Start the Steep daemon (keeps RBS env in memory for faster checks)"
    task :start do
      sh "bundle exec steep server start"
    end

    desc "Stop the Steep daemon"
    task :stop do
      sh "bundle exec steep server stop"
    end

    desc "Restart the Steep daemon (after Steepfile or RBS changes)"
    task :restart do
      sh "bundle exec steep server restart"
    end

    desc "Show Steep daemon status"
    task :status do
      sh "bundle exec steep server status"
    end
  end
end
