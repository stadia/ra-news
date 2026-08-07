# typed: true

# Accessors this app defines at runtime with its own DSLs.
#
# Tapioca ships DSL compilers for Rails' generators, not for ours, so anything
# built with `define_singleton_method` or `define_method` here has to be
# mirrored by hand. Keep each block in sync with the source it mirrors -- the
# comment above each one names the file.

# app/models/preference.rb -- `define_dynamic_accessors`
#
# Which accessors a Preference row has depends on its `name` column, decided
# at runtime by a `case` in the private `define_dynamic_accessors`: rows whose
# name ends in `_oauth` get the OAuth set, `ignore_hosts` gets `hosts`. Sorbet
# sees a row as just a Preference, so it needs the union of every branch.
#
# Keep in sync with that `case`. A name that matches no branch gets none of
# these at runtime, which is why they are declared but not typed -- calling one
# on the wrong row raises NoMethodError, and no signature here would predict
# that.
class Preference
  def hosts; end

  def site; end
  def client_id; end
  def client_secret; end
  def signing_secret; end
  def access_token; end
  def refresh_token; end
  def expires_at; end
  def token_created_at; end
  def team_id; end
  def key_id; end
end

# app/channels/application_cable/connection.rb -- `identified_by :current_user`
#
# ActionCable defines the reader and writer for each identifier with
# `define_method` at class-definition time, and Tapioca ships no DSL compiler
# for it.
module ApplicationCable
  class Connection
    sig { returns(T.nilable(::User)) }
    def current_user; end

    sig { params(value: T.nilable(::User)).returns(T.nilable(::User)) }
    def current_user=(value); end
  end
end
