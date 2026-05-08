# frozen_string_literal: true

class JsonFailureApp < Devise::FailureApp
  def respond
    if json_request?
      json_error_response
    else
      super
    end
  end

  private

  def json_request?
    request.format.json? || request.content_type.to_s.include?("json")
  end

  def json_error_response
    self.status = 401
    self.content_type = "application/json"
    self.response_body = { error: "unauthorized" }.to_json
  end
end
