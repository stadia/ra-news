# typed: true

# Hand-written shim for the `phlex-icons` gem.
#
# The gem is excluded from `tapioca gem` (see sorbet/tapioca/config.yml): it
# ships ~45k icon classes across 187MB of source, and reflecting over all of
# them takes over fifteen minutes and produces an RBI large enough to slow
# every `srb tc` run down.
#
# Declare an icon here when you start using it. Sorbet will report an
# unresolved constant otherwise, which is the intended signal.
#
# Most icons need TWO declarations, because the codebase calls them two ways:
#
#   render PhlexIcons::Hero::Rss.new(...)   -- the class
#   Hero::ArrowUturnLeft(...)               -- a singleton method
#
# The second form comes from `extend Phlex::Kit` in the gem's module. Kit's
# `const_added` hook runs `define_singleton_method(name) { |*args, **kwargs,
# &block| ... }` for every component constant, so `Hero::Foo(...)` parses as a
# method call rather than a constant reference -- Sorbet reports it as
# "Method `Foo` does not exist on `T.class_of(PhlexIcons::Hero)`" and needs its
# own entry. Left untyped by design: the arguments are each icon's `initialize`
# keywords, and spelling those out for 33 icons would buy nothing the runtime
# does not already enforce.

module PhlexIcons
  class Base < Phlex::SVG
    def initialize(**attrs); end

    def attrs; end
  end

  module Hero
    class ArrowLeft < ::PhlexIcons::Base; end
    class ArrowLongRight < ::PhlexIcons::Base; end
    class ArrowRight < ::PhlexIcons::Base; end
    class ArrowRightOnRectangle < ::PhlexIcons::Base; end
    class ArrowsRightLeft < ::PhlexIcons::Base; end
    class ArrowsRightLeftSolid < ::PhlexIcons::Base; end
    class ArrowTopRightOnSquare < ::PhlexIcons::Base; end
    class ArrowUturnLeft < ::PhlexIcons::Base; end
    class Bars3 < ::PhlexIcons::Base; end
    class Bell < ::PhlexIcons::Base; end
    class Calendar < ::PhlexIcons::Base; end
    class CalendarDays < ::PhlexIcons::Base; end
    class ChatBubbleLeft < ::PhlexIcons::Base; end
    class ChatBubbleLeftEllipsis < ::PhlexIcons::Base; end
    class ChatBubbleLeftRight < ::PhlexIcons::Base; end
    class ChatBubbleOvalLeftEllipsis < ::PhlexIcons::Base; end
    class CheckCircle < ::PhlexIcons::Base; end
    class ChevronDoubleLeft < ::PhlexIcons::Base; end
    class ChevronDoubleRight < ::PhlexIcons::Base; end
    class ChevronLeft < ::PhlexIcons::Base; end
    class ChevronRight < ::PhlexIcons::Base; end
    class Clock < ::PhlexIcons::Base; end
    class Cog6Tooth < ::PhlexIcons::Base; end
    class ExclamationCircle < ::PhlexIcons::Base; end
    class GlobeAlt < ::PhlexIcons::Base; end
    class Heart < ::PhlexIcons::Base; end
    class HeartSolid < ::PhlexIcons::Base; end
    class InformationCircle < ::PhlexIcons::Base; end
    class Key < ::PhlexIcons::Base; end
    class LockClosed < ::PhlexIcons::Base; end
    class Newspaper < ::PhlexIcons::Base; end
    class PencilSquare < ::PhlexIcons::Base; end
    class Rss < ::PhlexIcons::Base; end
    class Tag < ::PhlexIcons::Base; end
    class Trash < ::PhlexIcons::Base; end
    class User < ::PhlexIcons::Base; end
    class XCircle < ::PhlexIcons::Base; end

    class << self
      def ArrowLeft(*args, **kwargs, &block); end
      def ArrowLongRight(*args, **kwargs, &block); end
      def ArrowRight(*args, **kwargs, &block); end
      def ArrowsRightLeft(*args, **kwargs, &block); end
      def ArrowsRightLeftSolid(*args, **kwargs, &block); end
      def ArrowTopRightOnSquare(*args, **kwargs, &block); end
      def ArrowUturnLeft(*args, **kwargs, &block); end
      def Bell(*args, **kwargs, &block); end
      def Calendar(*args, **kwargs, &block); end
      def CalendarDays(*args, **kwargs, &block); end
      def ChatBubbleLeft(*args, **kwargs, &block); end
      def ChatBubbleLeftEllipsis(*args, **kwargs, &block); end
      def ChatBubbleLeftRight(*args, **kwargs, &block); end
      def ChatBubbleOvalLeftEllipsis(*args, **kwargs, &block); end
      def CheckCircle(*args, **kwargs, &block); end
      def ChevronDoubleLeft(*args, **kwargs, &block); end
      def ChevronDoubleRight(*args, **kwargs, &block); end
      def ChevronLeft(*args, **kwargs, &block); end
      def ChevronRight(*args, **kwargs, &block); end
      def Clock(*args, **kwargs, &block); end
      def ExclamationCircle(*args, **kwargs, &block); end
      def GlobeAlt(*args, **kwargs, &block); end
      def Heart(*args, **kwargs, &block); end
      def HeartSolid(*args, **kwargs, &block); end
      def InformationCircle(*args, **kwargs, &block); end
      def Key(*args, **kwargs, &block); end
      def LockClosed(*args, **kwargs, &block); end
      def Newspaper(*args, **kwargs, &block); end
      def PencilSquare(*args, **kwargs, &block); end
      def Tag(*args, **kwargs, &block); end
      def Trash(*args, **kwargs, &block); end
      def User(*args, **kwargs, &block); end
    end
  end

  module Tabler
    class Markdown < ::PhlexIcons::Base; end

    class << self
      def Markdown(*args, **kwargs, &block); end
    end
  end
end
