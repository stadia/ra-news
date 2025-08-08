# frozen_string_literal: true

# rbs_inline: enabled

class ActivitypubPublishJob < ApplicationJob
  queue_as :default
  
  rescue_from StandardError, with: :handle_error

  #: (Integer article_id) -> void
  def perform(article_id)
    article = Article.kept.find_by(id: article_id)
    return unless article

    logger.info "ActivitypubPublishJob started for article id: #{article_id}"

    actor = find_or_create_actor(article)
    return unless actor

    activity = actor.create_article_activity(article)
    
    # For now, just log the activity - federation to external servers would be added later
    logger.info "ActivityPub activity created: #{activity[:id]}"
    
    # Store the activity for outbox (could be added to a separate model later)
    Rails.logger.info "Article #{article.id} published to ActivityPub outbox for actor #{actor.username}"
    
    # Future enhancement: Publish to follower inboxes
    # publish_to_followers(activity, actor)
  end

  private

  def find_or_create_actor(article) #: (Article) -> ActivitypubActor?
    return nil unless article.site

    # Find existing actor for the site
    actor = ActivitypubActor.kept.find_by(site: article.site)
    
    unless actor
      # Create actor for the site
      username = article.site.name.parameterize.presence || "site-#{article.site.id}"
      
      # Ensure unique username
      counter = 1
      original_username = username
      while ActivitypubActor.exists?(username: username, domain: current_domain)
        username = "#{original_username}-#{counter}"
        counter += 1
      end

      actor = ActivitypubActor.create!(
        username: username,
        domain: current_domain,
        site: article.site,
        display_name: article.site.name,
        bio: article.site.description || "#{article.site.name}의 뉴스 피드"
      )
      
      logger.info "Created new ActivityPub actor: #{actor.username}@#{actor.domain}"
    end

    actor
  rescue ActiveRecord::RecordInvalid => e
    logger.error "Failed to create ActivityPub actor: #{e.message}"
    Honeybadger.notify(e, context: { article_id: article.id, site_id: article.site&.id })
    nil
  end

  def current_domain #: String
    Rails.application.config.hosts&.first || 
    ENV.fetch("DOMAIN", "localhost:3000")
  end

  def handle_error(exception) #: (StandardError) -> void
    logger.error "ActivitypubPublishJob failed: #{exception.message}"
    logger.error exception.backtrace.join("\n")
    Honeybadger.notify(exception)
  end
end