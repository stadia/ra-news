# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module HtmlSanitizable
  extend ActiveSupport::Concern

  ALLOWED_TAGS = %w[p br a strong em ul ol li blockquote code pre img].freeze

  included do
    before_save :sanitize_body
  end

  private

  def sanitize_body
    self.body = Rails::Html::SafeListSanitizer.new.sanitize(body, tags: ALLOWED_TAGS)
  end
end
