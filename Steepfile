# Steepfile for Ruby-News

D = Steep::Diagnostic

# This setup assumes you are using `rbs collection` to manage RBS for gems.
# Run `rbs collection install` to install the RBS files.
# Steep will automatically pick up the RBS files from the collection.

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

  # Generated Rails/DSL signatures are intentionally incomplete, so most app
  # code lacks types and would fail under the default severity. Use the lenient
  # base for that existing debt, but restore MethodReturnTypeAnnotationMismatch
  # (which `lenient` disables) so the hand-maintained inline return-type
  # annotations are actually validated instead of silently skipped.
  diagnostics = D::Ruby.lenient.dup
  diagnostics[D::Ruby::MethodReturnTypeAnnotationMismatch] = :hint
  configure_code_diagnostics(diagnostics)
end

# Target for the test suite
target :test do
  # Where to find test-specific RBS files
  signature "sig/test"

  # Directory to type check
  check "test"

  # Same lenient base as :app so test type gaps don't gate the build, while
  # still validating inline return-type annotations.
  test_diagnostics = D::Ruby.lenient.dup
  test_diagnostics[D::Ruby::MethodReturnTypeAnnotationMismatch] = :hint
  configure_code_diagnostics(test_diagnostics)
end
