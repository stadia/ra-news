# typed: true
# rbs_inline: disabled

# This file is hand-written RBI (Sorbet `sig` DSL), not Ruby source -- RBS
# inline (`#:`) annotations don't apply, so RBS inline generation is off.

# Constants that the generated gem RBIs do not cover.

# Federails ships its policies as engine-autoloaded files under app/policies,
# so `tapioca gem` -- which only reflects over what `require` loads -- never
# sees Federails::FederailsPolicy. Its subclasses in the generated RBI then
# point at an unresolved parent, and inherited lookups like
# Federails::Client::ActivityPolicy::Scope fail.
module Federails
  class FederailsPolicy
    class Scope; end
  end

  module Client
    # ActivityPolicy inherits Scope rather than defining it, so the generated
    # RBI has no entry for it -- unlike its siblings (ActorPolicy::Scope,
    # FollowingPolicy::Scope), which the gem declares outright. Referenced by
    # ActivitiesController#index.
    class ActivityPolicy::Scope < ::Federails::FederailsPolicy::Scope; end
  end
end

# `friendly` is added at runtime, which Sorbet can't resolve statically -- but
# for two different reasons on the model vs. the relation:
#  - Model (class << self): `extend FriendlyId` installs `friendly` through a
#    `self.extended` hook that Tapioca does not trace, so the generated RBI
#    omits it.
#  - Relation: it is *not* FriendlyId but `ActiveRecord::Delegation` forwarding
#    the model's singleton method, and Tapioca's model RBI does not project
#    that onto Article's generated relation classes.
class Article
  class << self
    sig { returns(PrivateRelation) }
    def friendly; end
  end

  class PrivateRelation
    sig { returns(PrivateRelation) }
    def friendly; end
  end
end

# The `herb` gem is excluded from `tapioca gem` (see sorbet/tapioca/config.yml),
# but reactionview's RBI subclasses Herb::Engine.
module Herb
  class Engine; end
end
