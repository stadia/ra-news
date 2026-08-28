# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Sessions', type: :request do
  fixtures :users, :federails_actors

  path '/api/v1/auth/login' do
    post '로그인' do
      tags 'Authentication'
      description <<~DESC
        이메일과 비밀번호로 로그인하여 JWT 액세스 토큰과 리프레시 토큰을 발급받습니다.

        응답 헤더 `Authorization`에 Bearer 토큰이 포함됩니다.
      DESC
      consumes 'application/json'
      produces 'application/json'
      security []
      parameter name: :body,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    user: {
                      type: :object,
                      properties: {
                        email: { type: :string, format: 'email', description: '이메일 주소' },
                        password: { type: :string, format: 'password', description: '비밀번호' }
                      },
                      required: %w[email password]
                    }
                  },
                  required: %w[user]
                }

      response '200', '로그인 성공' do
        let(:body) { { user: { email: 'john@example.com', password: 'password' } } }

        schema type: :object,
               properties: {
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     email: { type: :string },
                     name: { type: :string, nullable: true },
                     username: { type: :string },
                     unconfirmed_email: { type: :string, nullable: true },
                     confirmed_at: { type: :string, format: 'date-time', nullable: true },
                     likees_count: { type: :integer },
                     created_at: { type: :string, format: 'date-time' },
                     updated_at: { type: :string, format: 'date-time' },
                     avatar_url: { type: :string, nullable: true }
                   },
                   required: %w[id email username likees_count created_at updated_at]
                 },
                 refresh_token: { type: :string, description: '리프레시 토큰' }
               },
               required: %w[user refresh_token]

        run_test! do |response|
          expect(response.headers["Cache-Control"]).to eq("no-store")
        end
      end

      response '401', '로그인 실패' do
        let(:body) { { user: { email: 'bad@example.com', password: 'wrong' } } }

        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: %w[error]

        run_test!
      end
    end
  end

  path '/api/v1/auth/logout' do
    delete '로그아웃' do
      tags 'Authentication'
      description '현재 사용자의 세션을 종료하고 모든 리프레시 토큰을 폐기합니다. 인증이 필요합니다.'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response '204', '로그아웃 성공' do
        let(:Authorization) do
          post api_v1_auth_login_path, params: { user: { email: users(:john).email, password: 'password' } }, as: :json
          response.headers['Authorization']
        end

        run_test!
      end

      response '204', '미인증 상태에서도 성공 (멱등)' do
        let(:Authorization) { nil }

        run_test!
      end
    end
  end
end
