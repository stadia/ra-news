# frozen_string_literal: true

class ArticlesSidebarComponent < ViewComponent::Base
  def initialize(popular_tags:, current_tag: nil)
    @popular_tags = popular_tags
    @current_tag = current_tag
  end

  private

  attr_reader :popular_tags, :current_tag
end