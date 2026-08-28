# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Feed', type: :request do
  fixtures :users, :federails_actors

  def auth_token(user)
    post api_v1_auth_login_path, params: { user: { email: user.email, password: 'password' } }, as: :json
    response.headers['Authorization']
  end

  path '/feed' do
    get '피드 조회' do
      tags 'Feed'
      description '현재 사용자의 팔로잉, 자신의 포스트, 부스트된 포스트를 시간순으로 반환합니다. 인증이 필요합니다.'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :page,
                in: :query,
                type: :integer,
                required: false,
                description: '페이지 번호 (countless 페이지네이션)'

      response '200', '피드 조회 성공' do
        schema type: :object,
               properties: {
                 posts: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       slug: { type: :string, nullable: true },
                       body: { type: :string },
                       post_type: { type: :string, enum: %w[short blog comment] },
                       status: { type: :string, nullable: true },
                       created_at: { type: :string, format: 'date-time' },
                       updated_at: { type: :string, format: 'date-time' },
                       likes_count: { type: :integer },
                       boosts_count: { type: :integer },
                       liked: { type: :boolean },
                       boosted: { type: :boolean },
                       author_name: { type: :string, nullable: true },
                       author_host: { type: :string, nullable: true },
                       author_avatar_url: { type: :string, nullable: true },
                       article_slug: { type: :string, nullable: true },
                       parent_slug: { type: :string, nullable: true },
                       boosted_by: { type: :string, nullable: true },
                       media_attachments: {
                         type: :array,
                         items: {
                           type: :object,
                           properties: {
                             url: { type: :string },
                             mediaType: { type: :string, nullable: true },
                             name: { type: :string, nullable: true }
                           },
                           required: %w[url]
                         }
                       }
                     },
                     required: %w[id body post_type created_at updated_at likes_count boosts_count liked boosted media_attachments]
                   }
                 },
                 pagination: {
                   type: :object,
                   properties: {
                     next_page: { type: :string, nullable: true },
                     limit: { type: :integer }
                   },
                   required: %w[limit]
                 }
               },
               required: %w[posts pagination]

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
