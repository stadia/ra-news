require "federails/data_transformer/note"

Federails.config_from "federails"

Rails.application.config.after_initialize do
  Federails::ServerController.class_eval do
    private

    def current_user
      nil
    end
  end

  # Federation: followers_url HTTP 자기 참조 문제 해결
  # Federails 기본 구현은 followers_url을 HTTP로 fetch하여 inbox를 resolve하는데,
  # 자기 서버에 HTTP 요청이 실패하여 inbox가 빈 배열로 반환됨.
  # DB에서 직접 팔로워를 조회하도록 override.
  begin
    require "fediverse/notifier"
  rescue LoadError
    # assets:precompile 등에서는 로드 불필요
  end

  if defined?(Fediverse::Notifier)
    Fediverse::Notifier.singleton_class.prepend(Module.new do
      private

      def inboxes_for(activity)
        return [] unless activity.actor.local?

        actor_inbox = activity.actor.inbox_url

        # DB에서 원격 팔로워의 inbox를 직접 조회
        follower_inboxes = Federails::Following
          .accepted
          .where(target_actor: activity.actor)
          .includes(:actor)
          .filter_map { |f| f.actor.inbox_url unless f.actor.local? }

        # addressing에서 followers_url을 제외한 직접 언급된 actor 처리
        followers_urls = [
          activity.actor.followers_url,
          (activity.entity.try(:followers_url) if activity.entity.try(:local?))
        ].compact

        addressing = [
          activity.to, activity.cc, activity.try(:bto), activity.try(:bcc), activity.try(:audience)
        ].flatten.compact.uniq
          .reject { |url| url == Fediverse::Collection::PUBLIC }
          .reject { |url| followers_urls.include?(url) }

        direct_inboxes = addressing.filter_map do |url|
          Federails::Actor.find_or_create_by_federation_url(url).inbox_url
        rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
          nil
        end

        resolved = (follower_inboxes + direct_inboxes).compact.uniq.reject { |url| url == actor_inbox }

        Rails.logger.info { "[Federation] Activity##{activity.id} (#{activity.action} #{activity.entity_type}##{activity.entity_id})" }
        Rails.logger.info { "[Federation] Resolved #{resolved.size} inboxes: #{resolved.inspect}" }

        resolved
      end

      def post_to_inbox(inbox_url:, message:, from: nil)
        Rails.logger.info { "[Federation] Delivering to inbox: #{inbox_url}" }
        result = super
        Rails.logger.info { "[Federation] Delivery result to #{inbox_url}: #{result&.status}" }
        result
      rescue => e
        Rails.logger.error { "[Federation] Delivery FAILED to #{inbox_url}: #{e.class} - #{e.message}" }
        raise
      end
    end)
  end
end
