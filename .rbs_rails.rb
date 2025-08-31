RbsRails.configure do |config|
  # Specify the directory where RBS signatures will be generated
  # Default: Rails.root.join("sig/rbs_rails")
  config.signature_root_dir = "sig/rbs_rails"

  # Define which models should be ignored during generation
  config.ignore_model_if do |klass|
    # Example: Ignore test models
    klass.name.start_with?("Test") ||
    # Example: Ignore models in specific namespaces
    klass.name.start_with?("Admin::") ||
    # Example: Ignore models without database tables
    !klass.table_exists?
  end
end
