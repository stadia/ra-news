# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Auth Tokens', type: :request do
  fixtures :users, :federails_actors

  path '/api/v1/auth/refresh' do
    post '액세스 토큰 갱신' do
      tags 'Authentication'
      description <<~DESC
        리프레시 토큰을 사용하여 새로운 액세스 토큰을 발급받습니다.
        기존 리프레시 토큰은 폐기(revoke)되고, 새 리프레시 토큰이 함께 발급됩니다.

        ## 응답 필드
        - `access_token`: 새 JWT 액세스 토큰
        - `refresh_token`: 새 리프레시 토큰
        - `expires_in`: 액세스 토큰 만료 시간 (초)
      DESC
      consumes 'application/json'
      produces 'application/json'
      security []
      parameter name: :body,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    refresh_token: { type: :string, description: '유효한 리프레시 토큰' }
                  },
                  required: %w[refresh_token]
                }

      response '200', '토큰 갱신 성공' do
        schema type: :object,
               properties: {
                 access_token: { type: :string, description: 'JWT 액세스 토큰' },
                 refresh_token: { type: :string, description: '새 리프레시 토큰' },
                 expires_in: { type: :integer, description: '액세스 토큰 만료 시간(초)' }
               },
               required: %w[access_token refresh_token expires_in]

        let(:user) { users(:john) }
        let(:_raw) do
          raw = SecureRandom.urlsafe_base64(64)
          RefreshToken.create!(
            user: user,
            token_digest: RefreshToken.digest(raw),
            expires_at: 30.days.from_now
          )
          raw
        end
        let(:body) { { refresh_token: _raw } }

        run_test!
      end

      response '401', '유효하지 않은 리프레시 토큰' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: %w[error]

        let(:body) { { refresh_token: 'invalid_token' } }

        run_test!
      end
    end
  end
end
