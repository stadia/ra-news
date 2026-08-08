# typed: true

# Gem DSL blocks whose `self` is rebound at runtime.
#
# `tapioca gem` records these methods as taking a plain `&block`, so Sorbet
# resolves calls inside the block against the *enclosing* class -- reporting
# every DSL call as "method does not exist". Redeclaring the method with a
# `T.proc.bind(...)` block tells Sorbet what `self` actually is inside.
#
# Keep each entry in sync with the generated RBI it overrides: same parameter
# names and arity, or Sorbet reports a redefinition mismatch instead.

module ActiveSupport::Concern
  # `included do ... end` is `class_eval`d on whichever class includes the
  # concern, so its `self` is that class -- but the concern itself cannot name
  # it, and `requires_ancestor` does not reach the block (it constrains the
  # module, not the singleton `self` of a `class_eval`). Without a bind Sorbet
  # resolves `has_many`/`before_save`/`validate`/`around_action` against
  # `T.class_of(TheConcern)` and reports each as a missing method.
  #
  # `T.untyped` rather than a concrete class: model, controller and job concerns
  # all use this hook, so there is no single includer to name.
  sig do
    params(
      base: T.untyped,
      block: T.nilable(T.proc.bind(T.untyped).void)
    ).returns(T.untyped)
  end
  def included(base = T.unsafe(nil), &block); end
end

module Alba::Resource::ClassMethods
  # lib/alba/resource.rb -- `attribute :x do |obj| ... end` blocks are
  # `instance_exec`d on the resource *instance* during serialization, which is
  # where `params` (and `object`) live. Without the bind Sorbet resolves
  # `params` against the serializer's singleton class.
  #
  # Used by app/serializers/*.rb.
  sig do
    params(
      name: T.untyped,
      if: T.untyped,
      name_with_type: T.untyped,
      block: T.nilable(T.proc.bind(Alba::Resource::InstanceMethods).params(arg0: T.untyped).returns(T.untyped))
    ).returns(T.untyped)
  end
  def attribute(name = T.unsafe(nil), if: T.unsafe(nil), **name_with_type, &block); end
end

class RubyLLM::Agent
  class << self
    # lib/ruby_llm/agent.rb -- `schema { ... }` is class_eval'd on an anonymous
    # RubyLLM::Schema subclass, which is where `string`/`array`/`object`/
    # `integer`/`number`/`boolean` live (RubyLLM::Schema::DSL::*, extended).
    #
    # Used by app/agents/*.rb.
    sig do
      params(
        value: T.untyped,
        block: T.nilable(T.proc.bind(T.class_of(RubyLLM::Schema)).void)
      ).returns(T.untyped)
    end
    def schema(value = nil, &block); end
  end
end

module Mail
  class << self
    # lib/mail/mail.rb -- `Mail.defaults { ... }` instance_eval's the block on
    # the Mail::Configuration singleton, which is where `retriever_method` and
    # `delivery_method` live.
    #
    # Used by app/clients/gmail.rb.
    sig { params(block: T.proc.bind(::Mail::Configuration).void).returns(T.untyped) }
    def defaults(&block); end
  end
end
