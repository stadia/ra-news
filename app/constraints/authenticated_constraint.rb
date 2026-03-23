# frozen_string_literal: true

class AuthenticatedConstraint
  def matches?(request)
    warden = request.env["warden"]
    warden&.authenticated?(:user) && warden.user(:user)&.admin? || false
  end
end
