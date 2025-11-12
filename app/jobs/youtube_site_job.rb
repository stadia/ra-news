# frozen_string_literal: true

# rbs_inline: enabled

class YoutubeSiteJob < ApplicationJob
  def self.enqueue_all
    YoutubeSiteJob.perform_later(Site.kept.youtube.order("id ASC").pluck(:id))
  end

  #: (Array[Integer] ids) -> void
  def perform(ids)
    ids = [ ids ] unless ids.is_a?(Array)
    site_id = ids.shift
    site = Site.find(site_id)
    return if site.nil?

    videos = site.init_client&.videos
    return if videos.nil?

    videos.each do |video|
      break if site.last_checked_at > video.published_at

      # 정규화된 URL 사용
      url = "https://#{Article::YOUTUBE_NORMALIZED_HOST}/watch?v=#{video.id}"
      Article.create(url: url, origin_url: url, title: video.title, published_at: video.published_at, site:) unless Article.exists?(origin_url: url)
      sleep 1
    end

    site.update(last_checked_at: Time.zone.now)
    YoutubeSiteJob.perform_later(ids) unless ids.empty?
  end
end
