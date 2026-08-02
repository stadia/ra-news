# typed: true

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

# The `herb` gem is excluded from `tapioca gem` (see sorbet/tapioca/config.yml),
# but reactionview's RBI subclasses Herb::Engine.
module Herb
  class Engine; end
end
