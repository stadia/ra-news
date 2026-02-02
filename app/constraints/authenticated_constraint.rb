# frozen_string_literal: true

# rbs_inline: enabled

class AuthenticatedConstraint
  def matches?(request) #: (ActionDispatch::Request) -> bool
    session_id = request.cookie_jar.signed[:session_id]
    return false if session_id.blank?

    Session.includes(:user).find_by(id: session_id)&.user&.admin? || false
  end
end
