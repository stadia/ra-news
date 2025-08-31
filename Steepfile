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
  check "app/models"
  check "app/controllers"
  check "app/jobs"
  check "app/services"
  check "app/clients"
  check "lib"

  # Ignore generated or less critical files
  ignore "lib/tasks/**/*.rake"
  ignore "lib/protobuf/**/*"

  # Set the default diagnostic level.
  # :strict is a good goal, but :default is a good starting point.
  configure_code_diagnostics(D::Ruby.default)
end

# Target for the test suite
# target :test do
#   # Where to find test-specific RBS files
#   signature "sig/test"

#   # Directory to type check
#   check "test"

#   # Use a more relaxed setting for tests
#   configure_code_diagnostics(D::Ruby.lenient)
# end
