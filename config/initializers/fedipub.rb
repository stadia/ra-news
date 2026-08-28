require "fediverse/inbox"

Alba.backend = :oj_rails

Fedipub.config_from "fedipub"

Fedipub.configure do |config|
  config.logger = Rails.logger
  config.remote_follow_url_method = :new_following_url
end

# threads.net의 ActivityPub inbox는 빈번하게 HTTP 500을 반환하므로 배달을 스킵한다.
# Why: TemporaryDeliveryError가 누적되며 워커 큐를 채우고 알림이 시끄러워짐.
module SkipBrokenInboxHosts
  SKIPPED_HOSTS = %w[threads.net www.threads.net].freeze

  def perform(activity, inbox_url = nil)
    if inbox_url && SKIPPED_HOSTS.include?(URI(inbox_url).host)
      Rails.logger.info { "Skipping federated delivery to #{inbox_url}" }
      return
    end
    super
  end
end
Rails.application.config.to_prepare do
  Fedipub::NotifyInboxJob.prepend(SkipBrokenInboxHosts)
end
