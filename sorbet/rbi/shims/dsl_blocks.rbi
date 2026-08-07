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
