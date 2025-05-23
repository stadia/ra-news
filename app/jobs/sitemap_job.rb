# frozen_string_literal: true

# rbs_inline: enabled

class SitemapJob < ApplicationJob
  def perform #: void
    Rails.application.load_tasks # Rake tasks 로드
    Rake::Task["sitemap:refresh:no_ping"].invoke # 특정 Rake task 실행
  end
end
