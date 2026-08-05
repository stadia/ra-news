# typed: strict
# frozen_string_literal: true
# rbs_inline: enabled

module Tapioca
  module Dsl
    module Compilers
      # Generates the controller helpers Devise defines per mapping.
      #
      # `devise_for :users` in routes.rb makes Devise call
      # `Devise::Controllers::Helpers.define_helpers(mapping)`, which defines
      # `current_user`, `user_signed_in?`, `authenticate_user!` and
      # `user_session` with `class_eval`. None of that exists until the routes
      # have been drawn, so `tapioca gem` -- which reflects over what `require`
      # loads -- never sees it.
      #
      # Reading `Devise.mappings` rather than hardcoding "user" is the point of
      # doing this as a compiler: add `devise_for :admins` and the next
      # `bin/tapioca dsl` run produces the admin helpers too, where a
      # hand-written shim would silently stay behind.
      #
      # Emitted untyped. `current_user` is genuinely nil for a signed-out
      # request, but this app's global `authenticate_user!` means the ~40 call
      # sites never handle nil -- declaring `T.nilable(User)` would demand
      # nil-handling they do not need, and `User` would be a lie.
      #
      #: [ConstantType = singleton(::ActionController::Base)]
      class DeviseControllerHelpers < Tapioca::Dsl::Compiler
        # @override
        #: -> void
        def decorate
          mappings = devise_mappings
          return if mappings.empty?

          root.create_path(constant) do |klass|
            mappings.each do |mapping|
              klass.create_method("current_#{mapping}", return_type: "T.untyped")
              klass.create_method("#{mapping}_signed_in?", return_type: "T.untyped")
              klass.create_method("#{mapping}_session", return_type: "T.untyped")
              klass.create_method(
                "authenticate_#{mapping}!",
                parameters: [
                  create_opt_param("opts", type: "T.untyped", default: "{}")
                ],
                return_type: "T.untyped"
              )
            end
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            # `ActionController::Base` rather than each controller: Devise
            # includes its helpers there once, and emitting them per subclass
            # would repeat the same four methods across every controller RBI.
            return [] unless defined?(::Devise) && defined?(::ActionController::Base)

            [ ::ActionController::Base ]
          end
        end

        private

        #: -> Array[Symbol]
        def devise_mappings
          ::Devise.mappings.keys.sort
        end
      end
    end
  end
end
