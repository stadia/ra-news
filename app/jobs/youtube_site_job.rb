# frozen_string_literal: true

# rbs_inline: enabled

class YoutubeSiteJob < ApplicationJob
  #: (id Integer) -> void
  def perform(id = nil)
    if id.nil?
      jobs = []
      Site.youtube.find_each.with_index do |site, index|
        jobs << YoutubeSiteJob.new(site.id).set(wait: (index * 1).minutes)
      end
      ActiveJob.perform_all_later(jobs)
      return
    end

    site = Site.find_by(id:)
    return if site.nil?

    videos = site.init_client&.videos
    return if videos.nil?

    videos.each do |video|
      break if site.last_checked_at > video.published_at

      # 정규화된 URL 사용
      url = "https://#{Article::YOUTUBE_NORMALIZED_HOST}/watch?v=#{video.id}"
      Article.create(url: url, origin_url: url, title: video.title, published_at: video.published_at, site:) unless Article.exists?(origin_url: url)
    end

    site.update(last_checked_at: Time.zone.now)
  end
end
