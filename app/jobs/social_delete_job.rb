# frozen_string_literal: true

# rbs_inline: enabled

class SocialDeleteJob < ApplicationJob
  queue_as :default

  #: (Integer id) -> void
  def perform(id)
    return unless Rails.env.production?

    article = Article.find_by(id: id)

    TwitterService.new.call(article, command: :delete)
    MastodonService.new.call(article, command: :delete)
  end
end
