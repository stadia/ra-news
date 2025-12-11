# frozen_string_literal: true

# rbs_inline: enabled

class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: { ie: false }

   before_action do
    Honeybadger.context({
      user_id: Current.user&.id
    })
  end
end
