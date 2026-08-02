# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

module Madmin
  class SocialController < Madmin::ApplicationController
    # Social 메뉴 메인 페이지
    #: () -> void
    def index
      @social_list = Preference.where("name like ?", "%_oauth")
    end
  end
end
