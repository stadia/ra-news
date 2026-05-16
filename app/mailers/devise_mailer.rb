# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  def default_url_options
    base = super || {}
    host = @resource&.respond_to?(:signup_host) ? @resource.signup_host.presence : nil
    host ? base.merge(host: host) : base
  end

  def confirmation_instructions(record, token, opts = {})
    @token = token
    initialize_from_record(record)

    mail(headers_for(:confirmation_instructions, opts)) do |format|
      format.text
      format.html do
        render renderable: Views::Devise::Mailer::ConfirmationInstructions.new(
          resource:,
          confirmation_url: user_confirmation_url(confirmation_token: @token)
        )
      end
    end
  end
end
