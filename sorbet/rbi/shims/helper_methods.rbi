# typed: true
# rbs_inline: enabled

# Helper/concern modules call methods their includer provides -- `logger` on a
# job, `render`/`image_tag`/`current_page?` on a controller -- or Kernel methods
# (`raise`, `sleep`) that Sorbet does not surface on a bare module. Nothing in
# the module says what the includer is, so Sorbet resolves `self` to the module
# and reports every such call as a missing method.
#
# These declarations state the contract each module expects from its includer.
# They live here rather than in the module source, which is kept free of
# Sorbet-specific constructs (type information lives in inline `#:` RBS comments
# and these shims).
#
# The class-level `LocaleSwitcher.around_action` entry exists because Sorbet
# types `included do ... end` as running on the module's *class*, even though it
# is `class_eval`'d on the includer at runtime. Declaring the method on the class
# satisfies that typing; at runtime the call resolves to the includer's method.

module RssHelper
  sig { returns(Logger) }
  def logger; end

  sig { params(args: T.untyped).returns(T.untyped) }
  def raise(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def sleep(*args); end
end

module LinkHelper
  sig { returns(Logger) }
  def logger; end
end

module ApplicationHelper
  sig { params(args: T.untyped).returns(T.untyped) }
  def image_tag(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def current_page?(*args); end

  sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
  def render(*args, &block); end
end

module LocaleSwitcher
  class << self
    sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
    def around_action(*args, &block); end
  end
end
