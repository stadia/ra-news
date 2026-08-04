# Steepfile for Ruby-News

D = Steep::Diagnostic

# This setup assumes you are using `rbs collection` to manage RBS for gems.
# Run `rbs collection install` to install the RBS files.
# Steep will automatically pick up the RBS files from the collection.

# --- Diagnostic scope ------------------------------------------------------
#
# The base is `strict` and debt is subtracted from it, NOT the other way round.
#
# This used to start from `lenient` and promote the diagnostics that happened to
# be clean. That allowlist reached 39 of Steep's 58 entries and was fail-open in
# the wrong direction: anything not on it -- including diagnostics added by a
# future Steep release -- stayed silently lenient. Inverting it makes the list
# shorter (19), makes each entry justify itself with a count and a reason, and
# makes a Steep upgrade enforce new checks by default. Removing an entry from
# `DEBT` is now how you widen the gate.
#
# Steep gates on severity >= :warning, so `:hint` here means "reported, not
# enforced".
#
# Counts are from 2026-08-04 (12,844 problems total). Re-measure with a copy of
# this file that swaps `configure_code_diagnostics(DIAGNOSTICS.call)` for
# `configure_code_diagnostics(D::Ruby.all_error)` -- and keep the copy in the
# project root, or the relative `check` paths resolve to nothing and it passes
# having checked zero files.
DEBT = {
  # --- The signature-coverage wall (12,292 of the 12,844) -------------------
  # Not fixable one call site at a time. Phlex ships no RBS and there are no
  # ActiveRecord column signatures, so most receivers are untyped and every
  # call on them lands here. Closing this needs generated Rails/Phlex RBS
  # (rbs_rails or similar), not annotations.
  D::Ruby::NoMethod => 7975,
  D::Ruby::FallbackAny => 1900,
  D::Ruby::UnknownConstant => 1269,
  D::Ruby::MethodDefinitionInUndeclaredModule => 679,
  D::Ruby::UnknownInstanceVariable => 469,

  # --- Fixable, just not yet ------------------------------------------------
  # Mechanical annotation work. Highest count first; each is a candidate for
  # the next pass.
  D::Ruby::UnannotatedEmptyCollection => 233,
  D::Ruby::UnresolvedOverloading => 93,
  D::Ruby::ArgumentTypeMismatch => 45,
  D::Ruby::UndeclaredMethodDefinition => 44,
  D::Ruby::MethodDefinitionMissing => 33,
  D::Ruby::UnreachableBranch => 30,

  # --- Blocked on gem RBS ---------------------------------------------------
  # Gem signatures narrower than the real methods. Fixable one `| ...` overload
  # at a time in sig/shims/external.rbs; ~30 separate gaps across Yt, Slack,
  # schema_dot_org, Devise, Madmin, ActiveRecord.
  D::Ruby::UnexpectedKeywordArgument => 17,
  D::Ruby::UnexpectedPositionalArgument => 13,
  D::Ruby::UnexpectedSuper => 9,     # 2 of these need AR column signatures
  D::Ruby::RequiredBlockMissing => 8,

  # --- Blocked on Steep itself ----------------------------------------------
  # Not fixable in this codebase.
  #   UnsupportedSyntax  -- Steep 2.0 does not support splat-into-untyped
  #                         (`dig(*path)`, `includes(*CONST)`) or `case/in`.
  #   BlockTypeMismatch  -- `&:sym` and `&` forwarding type as bare `::Proc`
  #                         rather than a proc type.
  #   BlockBodyTypeMismatch -- `to_h { [k, v] }` wants `Hash::_Pair`.
  #   UnreachableValueBranch -- only "fixable" by deleting defensive `else`es.
  D::Ruby::UnsupportedSyntax => 16,
  D::Ruby::BlockTypeMismatch => 5,
  D::Ruby::BlockBodyTypeMismatch => 4,
  D::Ruby::UnreachableValueBranch => 2
}.freeze

# `strict` everywhere, `:hint` for the debt above.
# A lambda rather than a method: the Steepfile is `instance_eval`ed, and a `def`
# here would land on the outer DSL object and be invisible inside `target`.
DIAGNOSTICS = lambda do
  D::Ruby.strict.dup.tap do |diagnostics|
    DEBT.each_key { |key| diagnostics[key] = :hint }
  end
end

# Default target for the main application code
target :app do
  # Where to find application-specific RBS files
  signature "sig"
  # Directories to type check
  check "app"
  check "lib"
  # `config` and `db` were outside the checked scope until 2026-08-04. Adding
  # them cost nothing -- no ratcheted diagnostic fires there -- and the gate now
  # covers initializers, environments, routes and db/seeds.rb too.
  check "config"
  check "db"

  # Ignore generated or less critical files
  ignore "lib/tasks/**/*.rake"
  ignore "lib/protobuf/**/*"
  # Migrations are write-once history: they ran against the schema of their day
  # and are never edited again. Gating them would tax every future migration
  # for no runtime benefit -- and one existing backfill already trips
  # IncompatibleAssignment on `total += exec_update(...)`.
  ignore "db/migrate/**/*"

  configure_code_diagnostics(DIAGNOSTICS.call)
end

# Target for the test suite
target :test do
  # Where to find test-specific RBS files
  signature "sig/test"

  # Directory to type check
  check "test"

  # Same configuration as :app -- the debt measurement covered both targets.
  configure_code_diagnostics(DIAGNOSTICS.call)
end
