# typed: strict
# frozen_string_literal: true
# rbs_inline: enabled

module Tapioca
  module Dsl
    module Compilers
      # Generates signatures for the readers that `Configs::OauthBase.pref`
      # creates.
      #
      # `pref :client_id, env: "APPLE_CLIENT_ID"` runs
      # `define_singleton_method`, so nothing in the source spells `client_id`
      # and Sorbet reports every use as a missing method. A hand-written RBI
      # would fix that too, but it would go stale the moment someone adds a
      # `pref` line -- silently, because nothing compares the two. This
      # regenerates instead.
      #
      # Emitted untyped on purpose. A pref reader resolves in order -- the
      # Preference row, then Rails credentials, then ENV -- so it can always
      # come back nil, but callers only ever ask `.present?`. Declaring
      # `T.nilable(String)` would be accurate and would push nil-handling into
      # call sites that do not need it; declaring `String` would be a lie.
      #
      # Lives in `Tapioca::Dsl::Compilers` rather than a namespace of our own:
      # `--only NAME` resolves against `Tapioca::Dsl::Compilers::NAME` and
      # top-level `::NAME`, and nothing else.
      #
      #: [ConstantType = singleton(::Configs::OauthBase)]
      class ConfigsPref < Tapioca::Dsl::Compiler
        # Where `define_singleton_method` sits inside `pref`. Every generated
        # reader reports this as its source location, while a hand-written
        # `def self.configured?` reports its own file -- which is how the two
        # are told apart. Sorbet already sees the hand-written ones from
        # source, and redeclaring them here would be noise.
        PREF_DEFINITION_FILE = "app/models/configs/oauth_base.rb" #: String

        # @override
        #: -> void
        def decorate
          readers = pref_readers
          return if readers.empty?

          root.create_path(constant) do |klass|
            readers.each do |name|
              klass.create_method(name.to_s, class_method: true, return_type: "T.untyped")
            end
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            # Guarded here rather than with a top-level `return unless
            # defined?(...)`: compilers are required before anything
            # references the app's constants, and under Zeitwerk's lazy
            # loading that guard would return before the class was defined,
            # leaving tapioca to report "Cannot find compiler".
            return [] unless defined?(::Configs::OauthBase)

            descendants_of(::Configs::OauthBase)
          end
        end

        private

        #: -> Array[Symbol]
        def pref_readers
          constant.singleton_methods(false).select do |name|
            location = constant.method(name).source_location
            location && location.first.end_with?(PREF_DEFINITION_FILE)
          end.sort
        end
      end
    end
  end
end
