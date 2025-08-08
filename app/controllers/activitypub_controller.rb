# frozen_string_literal: true

# rbs_inline: enabled

class ActivitypubController < ApplicationController
  before_action :set_content_type
  before_action :find_actor, only: [:actor, :outbox]
  
  skip_before_action :verify_authenticity_token
  
  def actor
    render json: @actor.to_activitypub
  end

  def outbox
    activities = recent_article_activities(@actor)
    
    outbox_collection = {
      "@context": "https://www.w3.org/ns/activitystreams",
      "type": "OrderedCollection",
      "id": @actor.outbox_url,
      "totalItems": activities.size,
      "orderedItems": activities
    }
    
    render json: outbox_collection
  end

  def inbox
    # Handle incoming ActivityPub activities (for future federation)
    # For now, just return 202 Accepted
    head :accepted
  end

  private

  def set_content_type #: void
    response.headers["Content-Type"] = "application/activity+json; charset=utf-8"
  end

  def find_actor #: void
    @actor = ActivitypubActor.kept.find_by!(username: params[:username], domain: request.host)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Actor not found" }, status: :not_found
  end

  def recent_article_activities(actor) #: (ActivitypubActor) -> Array[Hash[String, untyped]]
    # Get recent articles from the actor's site
    articles = if actor.site
      Article.kept.where(site: actor.site).order(created_at: :desc).limit(20)
    else
      Article.kept.order(created_at: :desc).limit(20)
    end

    articles.map { |article| actor.create_article_activity(article) }
  end
end