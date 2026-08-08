# typed: true

# Self-types for model concerns.
#
# A concern calls methods that its includer provides -- `title_ko` on an
# Article, `federails_actor` on a Post -- but nothing in the module says what
# the includer is, so Sorbet resolves `self` to the bare module and reports
# every such call as a missing method.
#
# `requires_ancestor` states the relationship. It belongs here rather than in
# the concern's own source because the source is kept free of Sorbet-specific
# constructs: type information for this project lives in inline `#:` RBS
# comments and in these shims, and RBS has no way to spell a module self-type
# that Sorbet reads.
#
# Each entry is checked: Sorbet verifies the ancestor really is present
# wherever the module is included, so a wrong claim here fails the build rather
# than hiding.

module Articles::LocalizedDisplay
  extend T::Helpers

  requires_ancestor { Article }
end

module Articles::Activitypub
  extend T::Helpers

  requires_ancestor { Article }
end

module Posts::Federation
  extend T::Helpers

  requires_ancestor { Post }
end

module Posts::Blog
  extend T::Helpers

  requires_ancestor { Post }
end

# Controller concerns name `ApplicationController` rather than the individual
# controllers that include them: what they actually reach for is the inherited
# surface (`render`, `request`, `cookies`, `current_user`), and pinning to a
# single subclass would be both narrower than the truth and wrong the moment a
# second controller includes the module.
module PostViewing
  extend T::Helpers

  requires_ancestor { ApplicationController }
end

module RateLimiting
  extend T::Helpers

  requires_ancestor { ApplicationController }
end

module LocaleSwitcher
  extend T::Helpers

  requires_ancestor { ApplicationController }
end

# Job concerns name `ApplicationJob` rather than the individual jobs that
# include them: what they reach for is the inherited surface (`logger`,
# `raise`, `self.class`), and pinning to a single subclass would be both
# narrower than the truth and wrong the moment a second job includes the module.
module JobRateLimiting
  extend T::Helpers

  requires_ancestor { ApplicationJob }
end

# Not a `requires_ancestor`: DiscordArticlePresenter and SlackArticlePresenter
# both include this and share no superclass, so there is no single ancestor to
# name. They each supply `article`, which is the only thing the module calls on
# its includer -- declared here as the contract the module expects.
module ArticlePresentable
  def article; end
end
