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

# `friendly_id` and `after_discard`/`after_undiscard` are class methods
# installed by `extend FriendlyId` and `include Discard::Model` respectively.
# Tapioca does not reflect over these hooks (same mechanism as `friendly`
# above), so Sorbet reports them as missing on every model that uses them.
# Declared per-model because Sorbet does not project `included`-hook singleton
# methods onto their includers.
class Article
  class << self
    sig { params(args: T.untyped, kwargs: T.untyped).void }
    def friendly_id(*args, **kwargs); end

    sig { params(name: T.nilable(T.any(Symbol, String)), args: T.untyped, kwargs: T.untyped, block: T.nilable(T.proc.void)).void }
    def after_discard(name = nil, *args, **kwargs, &block); end

    sig { params(name: T.nilable(T.any(Symbol, String)), args: T.untyped, kwargs: T.untyped, block: T.nilable(T.proc.void)).void }
    def after_undiscard(name = nil, *args, **kwargs, &block); end
  end
end

class Post
  class << self
    sig { params(args: T.untyped, kwargs: T.untyped).void }
    def friendly_id(*args, **kwargs); end

    sig { params(name: T.nilable(T.any(Symbol, String)), args: T.untyped, kwargs: T.untyped, block: T.nilable(T.proc.void)).void }
    def after_discard(name = nil, *args, **kwargs, &block); end

    sig { params(name: T.nilable(T.any(Symbol, String)), args: T.untyped, kwargs: T.untyped, block: T.nilable(T.proc.void)).void }
    def after_undiscard(name = nil, *args, **kwargs, &block); end
  end
end

# `devise` is a class macro that mixes modules in at runtime, so Tapioca's
# static reflection never sees the resulting instance/class methods on `User`.
# Same gem-gap mechanism as `friendly_id`/`after_discard` above: declared here
# for the methods this app's typed controllers reach for.
class User
  # Devise::Models::Authenticatable (instance) -- reached via `result.user`.
  sig { returns(T::Boolean) }
  def active_for_authentication?; end

  class << self
    # Devise::Models::Confirmable (class methods) -- reached via `resource_class`.
    sig { params(attributes: T.untyped).returns(T.untyped) }
    def send_confirmation_instructions(attributes = T.unsafe(nil)); end

    sig { params(confirmation_token: T.untyped).returns(T.untyped) }
    def confirm_by_token(confirmation_token); end
  end
end

# Devise controllers inherit `resource_class` typed as `T::Class[T.anything]`,
# so the Confirmable class methods on the resource are unresolvable. The
# resource for this controller is always `User`, so narrow the return type.
module Users
  class ConfirmationsController
    sig { returns(T.class_of(User)) }
    def resource_class; end
  end
end

# The `herb` gem is excluded from `tapioca gem` (see sorbet/tapioca/config.yml),
# but reactionview's RBI subclasses Herb::Engine.
module Herb
  class Engine; end
end
