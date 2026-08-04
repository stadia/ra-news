# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class DeviseMailer < Devise::Mailer
  include RecipientHostRouting

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
