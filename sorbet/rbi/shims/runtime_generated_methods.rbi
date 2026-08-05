# typed: true

# Methods that exist only after something generates them at boot.
#
# `tapioca gem` reflects over what `require` loads, so a method a gem writes
# with `define_method`, `module_eval` or `method_missing` at boot time lands in
# no RBI at all -- neither the gem that defines the hook nor the gem that
# triggers it. Sorbet then reports "Method `x` does not exist", and the call
# site cannot fix it: the method is real, the signature is just missing.
#
# Everything here is deliberately left untyped (no `sig`). These are gaps in
# our knowledge of a third-party API, and inventing a signature would assert
# something we have not verified -- in particular `current_user`, where
# claiming a non-nilable `User` would be a lie and claiming `T.nilable(User)`
# would push nil-handling onto ~40 call sites that the app's global
# `authenticate_user!` already guarantees.
#
# Remove an entry when the upstream RBI grows the method.

# Devise generates `current_<mapping>`, `<mapping>_signed_in?` and
# `authenticate_<mapping>!` inside `Devise::Controllers::Helpers` when
# `define_helpers(mapping)` runs for each `devise_for` in routes.rb. Two
# reasons they are invisible: the methods only exist once the app's routes have
# been drawn, and the generated `Devise::Controllers::Helpers` is not among the
# modules the actionpack RBI records as included into `ActionController::Base`
# (only its own includes, `SignInOut` and `StoreLocation`, made it). Declaring
# them on `ActionController::Base` is what actually reaches every controller.
class ActionController::Base
  def current_user; end

  def user_signed_in?; end

  def authenticate_user!(opts = T.unsafe(nil)); end
end

# `AbstractController::Collector` gets one method per registered Mime type,
# written by `module_eval` at `abstract_controller/collector.rb:11`. The
# actionpack RBI has the built-ins (`atom`, `bmp`, `css`, `csv`, ...) but not
# `turbo_stream`, because that Mime type is registered by turbo-rails after
# actionpack has been reflected over. Declared here alongside its siblings
# rather than on `MimeResponds::Collector`, which is where the call site sees
# it but not where the method lives.
module AbstractController::Collector
  def turbo_stream(*_arg0, **_arg1, &_arg2); end
end

# `Faraday.get` and friends are not defined: `Faraday.method_missing` forwards
# any name that `default_connection` responds to (lib/faraday.rb:144). The RBI
# has the instance methods on `Faraday::Connection` but nothing class-level.
module Faraday
  class << self
    def get(url = T.unsafe(nil), params = T.unsafe(nil), headers = T.unsafe(nil), &block); end

    def post(url = T.unsafe(nil), body = T.unsafe(nil), headers = T.unsafe(nil), &block); end

    def delete(url = T.unsafe(nil), params = T.unsafe(nil), headers = T.unsafe(nil), &block); end
  end
end

# `Dry::Monads::Result` is the abstract parent of `Success` and `Failure`, and
# the generated RBI declares `value!` / `success?` / `failure?` on each subclass
# but not on the parent. Code that holds a `Result` -- which is what a service
# object returns before you know which arm it is -- therefore cannot call them.
# Upstream defines them on the parent as abstract methods that raise.
class Dry::Monads::Result
  def value!; end

  def success?; end

  def failure?; end
end
