# app/views/actors/show.rb
# frozen_string_literal: true

class Views::Actors::Show < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo

  def initialize(actor:)
    @actor = actor
  end

  def view_template
    content_for :title, @actor.name

    render RubyUI::Heading.new(level: 1) { @actor.name }

    section do
      render Views::Followings::FollowActions.new(actor: @actor)
    end

    section do
      if @actor.local?
        link_to "All activities", actor_activities_path(@actor)
      elsif @actor.profile_url
        link_to "Visit profile", @actor.profile_url
      end
    end

    actor_details
    follows_section
    followers_section
    recent_activities
  end

  private

  def actor_details
    section do
      render RubyUI::Heading.new(level: 2) { "Actor details" }

      detail("Federated url", @actor.federated_url)
      detail("Username", @actor.username)
      detail("Inbox URL", @actor.inbox_url)
      detail("Outbox URL", @actor.outbox_url)
      detail("Followers URL", @actor.followers_url)
      detail("Followings URL", @actor.followings_url)

      p do
        b { "Profile url: " }
        link_to("Profile", @actor.profile_url) if @actor.profile_url
      end

      p do
        b { "Federation address: " }
        plain @actor.at_address
      end

      p do
        if @actor.local? && @actor.entity_configuration[:profile_url_method]
          b { "Home page: " }
          link_to @actor.entity.send(@actor.entity_configuration[:username_field]),
                  Rails.application.routes.url_helpers.send(@actor.entity_configuration[:profile_url_method], @actor.entity)
        elsif @actor.profile_url
          b { "Federation profile URL (JSON): " }
          link_to @actor.name, @actor.profile_url
        else
          plain "(No homepage)"
        end
      end
    end
  end

  def follows_section
    hr

    section do
      render RubyUI::Heading.new(level: 2) { "Follows (Who is followed?)" }

      if @actor.following_follows.empty?
        p { "#{@actor.username} follows nothing" }
      end

      @actor.following_follows.each do |following|
        follow_row(following.target_actor)
      end
    end
  end

  def followers_section
    section do
      render RubyUI::Heading.new(level: 2) { "Followers (Who follows?)" }

      if @actor.following_followers.empty?
        p { "Nothing follows #{@actor.username}" }
      end

      @actor.following_followers.each do |following|
        follower_row(following)
      end
    end
  end

  def recent_activities
    section do
      render RubyUI::Heading.new(level: 2) { "10 last activities" }

      activities = @actor.activities.last(10)
      if activities.empty?
        p { "No activity to display" }
      end

      activities.each do |activity|
        render partial("federails/client/activities/activity", activity: activity)
      end
    end
  end

  def follow_row(target_actor)
    div do
      b { link_to target_actor.name, actor_url(target_actor) }
      plain " (#{target_actor.at_address})"
    end
  end

  def follower_row(following)
    div do
      b { link_to following.actor.name, actor_url(following.actor) }
      plain " (#{following.actor.at_address}) (#{following.status})"
    end
  end

  def detail(label, value)
    p do
      b { "#{label}: " }
      plain value.to_s
    end
  end
end
