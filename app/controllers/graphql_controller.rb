# frozen_string_literal: true

class GraphqlController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  skip_before_action :authenticate_user!
  before_action :authenticate_user_from_bearer_token

  def execute
    result = AlNewsSchema.execute(
      params[:query],
      variables: variables,
      context: { current_user: current_user }
    )

    render json: result
  end

  private
    def authenticate_user_from_bearer_token
      return if request.authorization.blank?

      authenticate_user!
    end

    def variables
      case params[:variables]
      when String
        params[:variables].present? ? JSON.parse(params[:variables]) : {}
      when Hash, ActionController::Parameters
        params[:variables]
      when nil
        {}
      else
        raise ArgumentError, "Unexpected parameter: variables"
      end
    end
end
