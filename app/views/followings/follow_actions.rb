# frozen_string_literal: true

class Views::Followings::FollowActions < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def self.dom_id_for(actor)
    identifier = actor.at_address.presence || actor.federated_url.presence || actor.profile_url.presence || "actor"
    "follow_actions_#{Digest::SHA256.hexdigest(identifier).first(12)}"
  end

  def initialize(actor:)
    @actor = actor
  end

  def view_template
    current = view_context.current_user
    policy = Federails::Client::FollowingPolicy.new(current, Federails::Following)

    div(id: self.class.dom_id_for(@actor), class: "flex flex-wrap items-center gap-3 mt-2") do
      if policy.create?
        authenticated_actions(current)
      elsif current.nil?
        logged_out_message
      end
    end
  end

  private

  def authenticated_actions(current)
    follow = current.federails_actor.follows?(@actor)

    if @actor.entity == current
      span(class: "text-content-muted text-sm") { t("followings.follow_actions.own_account") }
    elsif follow
      existing_follow(follow)
    else
      new_follow
    end

    incoming_follow_request(current)
  end

  def existing_follow(follow)
    if follow.pending?
      follow_status_badge(t("followings.follow_actions.requested"), variant: :amber)
    else
      follow_status_badge(t("followings.follow_actions.following"), variant: :green)
    end
    button_to follow.pending? ? t("followings.follow_actions.cancel_request") : t("followings.follow_actions.unfollow"),
      following_path(follow),
      method: :delete,
      form: { data: { turbo_stream: true } },
      class: "px-4 py-2 text-sm font-medium bg-surface-muted hover:bg-danger-solid text-content-secondary hover:text-danger-text rounded-lg border border-border-muted transition-colors cursor-pointer"
  end

  def new_follow
    button_to t("followings.follow_actions.follow"),
      follow_followings_path,
      params: { account: @actor.at_address },
      method: :post,
      form: { data: { turbo_stream: true } },
      class: "px-4 py-2 text-sm font-medium bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground rounded-lg transition-colors cursor-pointer"
  end

  def incoming_follow_request(current)
    followed = @actor.follows?(current.federails_actor)
    return unless followed

    if followed.pending?
      span(class: "text-content-muted text-sm") { t("followings.follow_actions.incoming_request", username: @actor.username) }
      button_to t("followings.follow_actions.accept"),
        accept_following_path(followed),
        method: :put,
        form: { data: { turbo_stream: true } },
        class: "px-4 py-2 text-sm font-medium bg-info-solid hover:bg-info-solid-hover text-brand-foreground rounded-lg transition-colors cursor-pointer"
    else
      span(class: "text-content-muted text-sm") { t("followings.follow_actions.incoming_following", username: @actor.username) }
    end
  end

  def logged_out_message
    p(class: "text-content-muted text-sm") do
      plain t("followings.follow_actions.logged_out")
      code(class: "ml-1 bg-surface px-1.5 py-0.5 rounded text-content-secondary text-xs") do
        plain @actor.at_address(prefix: "")
      end
    end
  end

  def follow_status_badge(text, variant:)
    render RubyUI::Badge.new(
      variant: variant,
      class: "inline-flex items-center rounded-lg px-4 py-2 text-sm font-medium"
    ) { text }
  end
end
