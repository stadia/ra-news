# frozen_string_literal: true

# rbs_inline: enabled

module ActivityPub
  module Handlers
    class LikeHandler < OperationService
      class << self
        def handle_like(activity)
          new.call(command: :handle_like, activity:)
        end

        def handle_undo_like(activity)
          new.call(command: :handle_undo_like, activity:)
        end
      end

      def call(command:, activity:)
        case command
        when :handle_like
          step apply_like(activity:)
        when :handle_undo_like
          step apply_undo_like(activity:)
        else
          Failure(:unknown_command)
        end
      end

      private

      def apply_like(activity:)
        actor = Federails::Actor.find_or_create_by_object(activity["actor"])
        likeable = resolve_likeable(activity["object"])
        return Success(nil) unless actor.present? && likeable.present?

        actor.like!(likeable)
        Success(likeable)
      end

      def apply_undo_like(activity:)
        actor = Federails::Actor.find_or_create_by_object(activity["actor"])
        original_like = activity["object"]
        likeable = resolve_likeable(original_like["object"])
        return Success(nil) unless actor.present? && likeable.present?

        actor.unlike!(likeable)
        Success(likeable)
      end

      def resolve_likeable(object)
        object_id = object.is_a?(Hash) ? object["id"] : object
        likeable = Post.find_by(federated_url: object_id) ||
                   Article.find_by(federated_url: object_id) ||
                   resolve_local_likeable(object_id)
        return unless likeable&.local_federails_entity?

        likeable
      rescue ActiveRecord::RecordNotFound, URI::InvalidURIError, ActionController::RoutingError
        nil
      end

      def resolve_local_likeable(object_id)
        route = Federails::Utils::Host.local_route(object_id)
        return unless route.present? &&
          route[:controller] == "federails/server/published" &&
          route[:action] == "show"

        case route[:publishable_type]
        when "posts"
          Post.find_by(id: route[:id])
        when "articles"
          Article.find_by(id: route[:id])
        end
      end
    end
  end
end
