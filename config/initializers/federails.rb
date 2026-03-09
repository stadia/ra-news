require "federails/data_transformer/note"

Federails.config_from "federails"

Rails.application.config.after_initialize do
  Federails::ServerController.class_eval do
    private

    def current_user
      nil
    end
  end

  # Federation delivery 디버깅 로깅
  ActiveSupport.on_load(:active_job) do
    require "fediverse/notifier"

    Fediverse::Notifier.singleton_class.prepend(Module.new do
      def post_to_inboxes(activity)
        Rails.logger.info { "[Federation] post_to_inboxes called for Activity##{activity.id} (#{activity.action} #{activity.entity_type}##{activity.entity_id})" }
        Rails.logger.info { "[Federation] Actor: #{activity.actor.username} (local=#{activity.actor.local?})" }
        Rails.logger.info { "[Federation] Addressing - to: #{activity.to.inspect}, cc: #{activity.cc.inspect}" }

        inboxes = send(:inboxes_for, activity)
        Rails.logger.info { "[Federation] Resolved inboxes: #{inboxes.inspect}" }

        if inboxes.none?
          Rails.logger.warn { "[Federation] No inboxes found - activity will not be delivered" }
          return
        end

        super
      end

      private

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
