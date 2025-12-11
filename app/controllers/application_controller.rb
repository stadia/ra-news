# frozen_string_literal: true

# rbs_inline: enabled

class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: { ie: false }

   before_action do
    Honeybadger.context({
      user_id: Current&.user&.id
    })
  end

  # Pundit 호환성을 위한 current_user 메서드
  def current_user #: () -> User?
    Current.user
  end
end
