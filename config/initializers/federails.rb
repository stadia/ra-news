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
        Rails.logger.info { "[Federation] Activity##{activity.id} (#{activity.action} #{activity.entity_type}##{activity.entity_id})" }
        return [] unless activity.actor.local?

        actor_inbox = activity.actor.inbox_url
        Rails.logger.info "[Federation] actor_inbox #{actor_inbox}"
        addressing = [
          activity.to,
          activity.cc,
          activity.try(:bto),
          activity.try(:bcc),
          activity.try(:audience)
        ].flatten.compact.uniq.reject { |url|
          Rails.logger.info "[Federation] url #{url}"
          url == Fediverse::Collection::PUBLIC
        }

        addressing.flat_map do |url|
          actor = Federails::Actor.find_or_create_by_federation_url(url)
          Rails.logger.info "[Federation] actor #{actor}"
          [ actor.inbox_url ]
        rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
          collection_to_actors(url).map(&:inbox_url)
        end.compact.uniq.reject { |url| url == actor_inbox }
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
