# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'RubyNews API',
        version: 'v1',
        description: <<~DESC
          RubyNews API provides access to curated tech news articles.

          ## Authentication
          This API uses JWT Bearer token authentication. After signing in via OAuth or email,
          include the access token in the `Authorization` header:
          ```
          Authorization: Bearer <access_token>
          ```
        DESC
      },
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          }
        }
      },
      security: [
        { bearer_auth: [] }
      ],
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://ruby-news.dev',
          description: 'Production server'
        }
      ]
    }
  }

  config.openapi_format = :yaml
end
