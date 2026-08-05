# typed: strict
# frozen_string_literal: true
# rbs_inline: enabled

module Tapioca
  module Dsl
    module Compilers
      # Generates the component methods that `Phlex::Kit` creates.
      #
      # A module that does `extend Phlex::Kit` gets a `const_added` hook. For
      # every component constant added to it, the hook runs both
      # `define_method(name)` and `define_singleton_method(name)`, so
      # `RubyUI::PaginationItem(href: "...")` is a method call, not a constant
      # reference, and `Button(**attrs)` works inside any class that includes
      # the module. None of that is visible statically.
      #
      # Scoped to constants defined under the app's own directory. Kit modules
      # from gems are deliberately excluded: `PhlexIcons::Hero` also extends
      # Kit, and it autoloads ~45k icon classes -- reflecting over those is the
      # exact cost that keeps phlex-icons out of `tapioca gem`, and it would
      # come straight back here. Those stay hand-declared in
      # sorbet/rbi/shims/phlex_icons.rbi, where the rule is "declare the ones
      # you use".
      #
      # Emitted untyped: the arguments are each component's `initialize`
      # keywords, which vary per component and which the runtime already
      # enforces.
      #
      #: [ConstantType = Module[top]]
      class PhlexKitMethods < Tapioca::Dsl::Compiler
        # @override
        #: -> void
        def decorate
          names = app_component_names
          return if names.empty?

          root.create_path(constant) do |mod|
            names.each do |name|
              # Both forms: the instance method reaches classes that include
              # the module, the singleton method reaches `RubyUI::Foo(...)`.
              mod.create_method(name.to_s, parameters: kit_parameters, return_type: "T.untyped")
              mod.create_method(name.to_s, parameters: kit_parameters, return_type: "T.untyped", class_method: true)
            end
          end

          # The same `const_added` hook also runs `constant.include(me)` on
          # every component, which is how one component calls another
          # (`Button(**attrs)` inside `CarouselNext`). Without this the methods
          # above exist on the module but no component can see them.
          names.each do |name|
            component = constant.const_get(name)
            next unless component.is_a?(Module)

            root.create_path(component) do |klass|
              klass.create_include(T.must(constant.name))
            end
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            return [] unless defined?(::Phlex::Kit)

            all_modules.select do |mod|
              mod.singleton_class.ancestors.include?(::Phlex::Kit)
            end
          end
        end

        private

        #: -> Array[RBI::TypedParam]
        def kit_parameters
          [
            create_rest_param("args", type: "T.untyped"),
            create_kw_rest_param("kwargs", type: "T.untyped"),
            create_block_param("block", type: "T.untyped")
          ]
        end

        # Component constants this app owns. `const_source_location` is what
        # separates them from a gem's -- and it does not force an autoload, so
        # asking about phlex-icons' 45k entries stays cheap.
        #: -> Array[Symbol]
        def app_component_names
          app_root = ::Rails.root.join("app").to_s

          constant.constants(false).select do |name|
            location = constant.const_source_location(name)
            location && location.first.to_s.start_with?(app_root)
          end.sort
        end
      end
    end
  end
end
