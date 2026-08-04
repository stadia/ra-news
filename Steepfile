# Steepfile for Ruby-News

D = Steep::Diagnostic

# This setup assumes you are using `rbs collection` to manage RBS for gems.
# Run `rbs collection install` to install the RBS files.
# Steep will automatically pick up the RBS files from the collection.

# --- Diagnostic scope ------------------------------------------------------
#
# Generated Rails/DSL signatures are intentionally incomplete, so most app code
# lacks types and would fail wholesale under `default`. The base stays
# `lenient`, and the scope is widened one diagnostic at a time.
#
# `CLEAN_DIAGNOSTICS` below are the diagnostics the codebase has *zero*
# occurrences of, measured by running `steep check` with `D::Ruby.all_error` on
# both targets. Raising them to their `strict` severity therefore costs nothing
# today and acts as a ratchet: the first new violation fails CI instead of
# quietly joining the debt pile.
#
# The list grows as debt is paid off. The last six entries -- ClassModuleMismatch
# through UnknownRecordKey -- were driven to zero rather than found at zero.
#
# Steep gates on severity >= :warning, so :hint/:information entries here are
# informational only.
#
# Remaining debt, with why each is still `lenient` (counts as of 2026-08-04).
# These were each investigated; none can currently be driven to zero:
#
#   UnreachableValueBranch 2       Steep proves an `else` unreachable. Only
#                                  "fixable" by deleting defensive branches.
#   BlockBodyTypeMismatch 4        `to_h { [k, v] }` -- Steep wants
#                                  `Hash::_Pair`, gets `Array[untyped]`.
#   BlockTypeMismatch 5            `&:sym` and `&` forwarding typed as bare
#                                  `::Proc` instead of a proc type.
#   RequiredBlockMissing 7         Anonymous block forwarding (`foo(&)`) plus
#                                  gem RBS that omits block forms.
#   UnexpectedSuper 9              Needs ActiveRecord schema signatures: two
#                                  are `super` from an attribute-writer
#                                  override (`Article#title=`,
#                                  `Preference#name=`) whose target only
#                                  exists once columns are typed. The other
#                                  seven are Devise/Madmin/ActionMailer RBS
#                                  declaring the controllers but not the
#                                  methods we override.
#   UnexpectedPositionalArgument 13
#   UnexpectedKeywordArgument 17   Gem RBS argument lists narrower than the
#                                  real methods. Fixable one `| ...` overload
#                                  at a time, but ~30 separate gem gaps.
#   UnsupportedSyntax 15           NOT fixable here -- Steep 2.0 does not
#                                  support splat-into-untyped (`dig(*path)`,
#                                  `includes(*CONST)`) or `case/in`.
#
# Beyond those, five diagnostics are the signature-coverage wall. They are not
# fixable one call site at a time -- they need real Phlex/Rails RBS:
#
#     UnknownInstanceVariable 469, MethodDefinitionInUndeclaredModule 677,
#     UnknownConstant 1229, FallbackAny 1899, NoMethod 7727
#
# Re-measure with:
#     bundle exec steep check --steepfile=<file using D::Ruby.all_error>
CLEAN_DIAGNOSTICS = [
  D::Ruby::AnnotationSyntaxError,
  D::Ruby::BreakTypeMismatch,
  D::Ruby::DeprecatedReference,
  D::Ruby::DifferentMethodParameterKind,
  D::Ruby::FalseAssertion,
  D::Ruby::ImplicitBreakValueMismatch,
  D::Ruby::IncompatibleAnnotation,
  D::Ruby::IncompatibleArgumentForwarding,
  D::Ruby::InsufficientPositionalArguments,
  D::Ruby::InsufficientTypeArgument,
  D::Ruby::InvalidIgnoreComment,
  D::Ruby::LibraryRBSError,
  D::Ruby::MethodArityMismatch,
  D::Ruby::MethodBodyTypeMismatch,
  D::Ruby::MethodParameterMismatch,
  D::Ruby::MethodReturnTypeAnnotationMismatch,
  D::Ruby::MultipleAssignmentConversionError,
  D::Ruby::ProcHintIgnored,
  D::Ruby::ProcTypeExpected,
  D::Ruby::RBSError,
  D::Ruby::RedundantIgnoreComment,
  D::Ruby::ReturnTypeMismatch,
  D::Ruby::SetterBodyTypeMismatch,
  D::Ruby::SetterReturnTypeMismatch,
  D::Ruby::SyntaxError,
  D::Ruby::TypeArgumentMismatchError,
  D::Ruby::UnexpectedDynamicMethod,
  D::Ruby::UnexpectedError,
  D::Ruby::UnexpectedJump,
  D::Ruby::UnexpectedJumpValue,
  D::Ruby::UnexpectedTypeArgument,
  D::Ruby::UnknownGlobalVariable,
  D::Ruby::UnsatisfiableConstraint,

  # Driven to zero, not found at zero -- see the PR that added this block.
  D::Ruby::ClassModuleMismatch,
  D::Ruby::IncompatibleAssignment,
  D::Ruby::InsufficientKeywordArguments,
  D::Ruby::UnexpectedBlockGiven,
  D::Ruby::UnexpectedYield,
  D::Ruby::UnknownRecordKey
].freeze

# Lenient base + strict severity for everything we are already clean on.
# A lambda rather than a method: the Steepfile is `instance_eval`ed, and a `def`
# here would land on the outer DSL object and be invisible inside `target`.
RATCHETED_DIAGNOSTICS = lambda do
  strict = D::Ruby.strict
  D::Ruby.lenient.dup.tap do |diagnostics|
    CLEAN_DIAGNOSTICS.each { |key| diagnostics[key] = strict.fetch(key) }
  end
end

# Default target for the main application code
target :app do
  # Where to find application-specific RBS files
  signature "sig"
  # Directories to type check
  check "app"
  check "lib"

  # Ignore generated or less critical files
  ignore "lib/tasks/**/*.rake"
  ignore "lib/protobuf/**/*"

  configure_code_diagnostics(RATCHETED_DIAGNOSTICS.call)
end

# Target for the test suite
target :test do
  # Where to find test-specific RBS files
  signature "sig/test"

  # Directory to type check
  check "test"

  # Same ratchet as :app -- the zero-occurrence measurement covered both targets.
  configure_code_diagnostics(RATCHETED_DIAGNOSTICS.call)
end
