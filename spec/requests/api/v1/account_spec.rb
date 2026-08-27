# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Current User', type: :request do
  fixtures :users, :federails_actors

  # Helper to get a valid JWT
  def auth_token(user)
    post api_v1_auth_login_path, params: { user: { email: user.email, password: 'password' } }, as: :json
    response.headers['Authorization']
  end

  path '/api/v1/account' do
    get '현재 사용자 정보 조회' do
      tags 'Account'
      description '현재 로그인된 사용자의 프로필 정보를 반환합니다. 인증이 필요합니다.'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response '200', '사용자 정보 반환 성공' do
        schema type: :object,
               properties: {
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     email: { type: :string, format: 'email' },
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
                 }
               },
               required: %w[user]

        let(:Authorization) { auth_token(users(:john)) }

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: %w[error]

        let(:Authorization) { nil }

        run_test!
      end
    end
  end
end
