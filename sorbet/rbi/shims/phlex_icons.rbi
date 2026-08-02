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

module PhlexIcons
  class Base < Phlex::SVG
    def initialize(**attrs); end

    def attrs; end
  end

  module Tabler
    class Markdown < ::PhlexIcons::Base; end
  end

  module Hero
    class ArrowRightOnRectangle < ::PhlexIcons::Base; end
    class Bars3 < ::PhlexIcons::Base; end
    class CheckCircle < ::PhlexIcons::Base; end
    class Cog6Tooth < ::PhlexIcons::Base; end
    class Rss < ::PhlexIcons::Base; end
    class User < ::PhlexIcons::Base; end
    class XCircle < ::PhlexIcons::Base; end
  end
end
