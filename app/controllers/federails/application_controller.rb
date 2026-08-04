# typed: strong
# frozen_string_literal: true
# rbs_inline: enabled

module Federails
  class ApplicationController < ::ApplicationController
    # Devise provides current_user and authenticate_user! via ::ApplicationController
  end
end
