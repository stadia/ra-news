# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# 웹(HTML) 로그인 전용. JSON/JWT 발급은 Api::V1::Auth::SessionsController가 맡는다.
class Users::SessionsController < Devise::SessionsController
  layout -> { Components::Layout }

  def new
    redirect_to root_url and return if user_signed_in?
    render Views::Sessions::New.new
  end
end
