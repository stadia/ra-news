# frozen_string_literal: true
# rbs_inline: enabled

class ApplicationMailer < ActionMailer::Base
  default from: "bot@ruby-news.kr"
  layout "mailer"

  def default_url_options
    base = super || {}
    host = recipient_signup_host
    host ? base.merge(host: host) : base
  end

  private

  def recipient_signup_host
    record = @resource || @user
    return unless record.respond_to?(:signup_host)

    record.signup_host.presence
  end
end
