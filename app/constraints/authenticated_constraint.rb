# frozen_string_literal: true
# rbs_inline: enabled

class AuthenticatedConstraint
  def matches?(request)
    warden = request.env["warden"]
    warden&.authenticated?(:user) && warden.user(:user)&.admin? || false
  end
end
