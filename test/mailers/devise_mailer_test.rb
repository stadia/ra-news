# frozen_string_literal: true

require "test_helper"

class DeviseMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  test "confirmation_instructions renders html from phlex and keeps text part" do
    user = users(:john)
    token = "test-token"

    mail = DeviseMailer.confirmation_instructions(user, token)

    assert_equal [ user.email ], mail.to
    assert_equal I18n.t("devise.mailer.confirmation_instructions.subject"), mail.subject

    html_part = mail.html_part
    text_part = mail.text_part

    assert_not_nil html_part
    assert_not_nil text_part
    assert_includes html_part.body.to_s, "Ruby-News"
    assert_includes html_part.body.to_s, I18n.t("devise.mailer.confirmation_instructions.title")
    assert_includes html_part.body.to_s, I18n.t("devise.mailer.confirmation_instructions.greeting", recipient: user.name)
    assert_includes html_part.body.to_s, I18n.t("devise.mailer.confirmation_instructions.action")
    assert_includes html_part.body.to_s, CGI.escapeHTML(user_confirmation_url(confirmation_token: token))
    assert_includes text_part.body.to_s, user_confirmation_url(confirmation_token: token)
  end
end
