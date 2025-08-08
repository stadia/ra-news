# frozen_string_literal: true

# rbs_inline: enabled

class WebfingerController < ApplicationController
  before_action :set_content_type
  skip_before_action :verify_authenticity_token

  def show
    resource = params[:resource]
    
    unless resource&.start_with?("acct:")
      render json: { error: "Invalid resource format" }, status: :bad_request
      return
    end

    acct = resource[5..] # Remove "acct:" prefix
    username, domain = acct.split("@", 2)
    
    unless domain == request.host
      render json: { error: "Domain not found" }, status: :not_found
      return
    end

    actor = ActivitypubActor.kept.find_by(username: username, domain: domain)
    
    unless actor
      render json: { error: "User not found" }, status: :not_found
      return
    end

    webfinger_response = {
      subject: resource,
      links: [
        {
          rel: "self",
          type: "application/activity+json",
          href: actor.actor_url
        }
      ]
    }

    render json: webfinger_response
  end

  private

  def set_content_type #: void
    response.headers["Content-Type"] = "application/jrd+json; charset=utf-8"
  end
end