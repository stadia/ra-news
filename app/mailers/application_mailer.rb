# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class ApplicationMailer < ActionMailer::Base
  include RecipientHostRouting

  default from: "bot@ruby-news.dev"
  layout "mailer"
end
