# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class Users::SessionsController < Devise::SessionsController
  layout -> { Components::Layout }

  skip_before_action :verify_authenticity_token, if: :skip_csrf_for_json_write?

  respond_to :html, :json

  def new
    redirect_to root_url and return if user_signed_in?
    render Views::Sessions::New.new
  end

  def destroy
    if request.format.json? && current_user
      current_user.refresh_tokens.active.update_all(revoked_at: Time.current)
    end
    super
  end

  private

  def respond_with(resource, _opts = {})
    if request.format.json?
      _record, raw = RefreshToken.issue(resource)
      render json: {
        user: UserSerializer.new(resource).serializable_hash,
        refresh_token: raw
      }, status: :ok
    else
      super
    end
  end

  def respond_to_on_destroy(non_navigational_status: :no_content)
    if request.format.json?
      head :no_content
    else
      super
    end
  end
end
