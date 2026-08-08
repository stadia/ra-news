# typed: true
# rbs_inline: enabled

class ApplicationJob
  class << self
    # `arguments` is an ActiveJob instance method. Sorbet types the
    # `rescue_from` block as class-level even though it runs in instance context.
    sig { returns(T::Array[T.untyped]) }
    def arguments; end
  end
end
