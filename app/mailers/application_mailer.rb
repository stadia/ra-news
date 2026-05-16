# frozen_string_literal: true
# rbs_inline: enabled

class ApplicationMailer < ActionMailer::Base
  include RecipientHostRouting

  default from: "bot@ruby-news.kr"
  layout "mailer"
end
