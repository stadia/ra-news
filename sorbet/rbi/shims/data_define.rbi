# typed: true

# Shims for `Data.define(...)` value objects.
#
# Sorbet cannot see through `Const = Data.define(:a, :b)` -- it reads the
# assignment as an ordinary constant, so referring to it as a type fails with
# "is not a class or type alias". Tapioca has no DSL compiler for plain `Data`
# (only for T::Struct), so these are declared by hand.
#
# Each value object is declared under a `<Name>Value` class and then aliased to
# the name the source uses. Declaring `class Entry` directly would instead make
# Sorbet reject the source's own `Entry = Data.define(...)` line with
# "Cannot initialize the class by constant assignment"; a constant alias gives
# the same usable type without fighting the assignment.
#
# Keep each entry in sync with the `Data.define` call it mirrors; the source
# already carries the member types as rbs-inline `#:` comments.

module SitemapBuilder
  # app/functions/sitemap_builder.rb
  class EntryValue < ::Data
    sig { returns(String) }
    def path; end

    sig { returns(T.nilable(String)) }
    def lastmod; end

    sig { returns(T::Array[String]) }
    def available; end
  end

  Entry = SitemapBuilder::EntryValue
end

module Articles
  module Search
    # app/functions/articles/search.rb
    class IndexResultValue < ::Data
      sig { returns(Pagy) }
      def pagy; end

      sig { returns(T::Array[Article]) }
      def articles; end

      sig { returns(T::Array[String]) }
      def suggestions; end
    end

    IndexResult = Articles::Search::IndexResultValue
  end
end

module OauthAccounts
  module Registration
    # app/functions/oauth_accounts/registration.rb
    class ResultValue < ::Data
      sig { returns(T::Boolean) }
      def success; end

      sig { returns(T::Boolean) }
      def success?; end

      sig { returns(User) }
      def user; end
    end

    Result = OauthAccounts::Registration::ResultValue
  end

  module Callbacks
    # app/functions/oauth_accounts/callbacks.rb -- sum type returned by
    # .handle_callback: SignIn when an existing user matched, CompleteSignup
    # when the caller still needs to pick a username.
    class SignInValue < ::Data
      sig { returns(User) }
      def user; end
    end

    class CompleteSignupValue < ::Data
      sig { returns(String) }
      def suggested_username; end
    end

    SignIn = OauthAccounts::Callbacks::SignInValue
    CompleteSignup = OauthAccounts::Callbacks::CompleteSignupValue
  end
end
