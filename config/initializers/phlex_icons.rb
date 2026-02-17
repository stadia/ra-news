PhlexIcons.configure do |config|
  config.default_variant = :solid
  config.helper_method_name = :phlex_icon # Default: :phlex_icon
  config.default_pack = :hero # Default: nil. Accepts :symbol, "string", or Class (e.g., PhlexIcons::Hero)
end
