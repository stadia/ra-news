# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Boosts', type: :request do
  fixtures :users, :articles, :sites, :fedipub_actors

  # Helper to get a valid JWT
  def auth_token(user)
    post api_v1_auth_login_path, params: { user: { email: user.email, password: 'password' } }, as: :json
    response.headers['Authorization']
  end

  path '/api/v1/articles/{article_id}/boost' do
    post '기사 부스트' do
      tags 'Boosts'
      description '지정된 기사를 부스트(공유)합니다. 인증이 필요합니다.'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :article_id,
                in: :path,
                type: :string,
                required: true,
                description: '기사 slug'

      response '201', '부스트 생성 성공' do
        schema type: :object,
               properties: {
                 boostable_type: { type: :string },
                 boostable_slug: { type: :string },
                 boosted: { type: :boolean },
                 boosts_count: { type: :integer }
               },
               required: %w[boostable_type boostable_slug boosted boosts_count]

        let(:article_id) { articles(:ruby_article).slug }
        let(:Authorization) { auth_token(users(:john)) }

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: %w[error]

        let(:article_id) { articles(:ruby_article).slug }
        let(:Authorization) { nil }

        run_test!
      end
    end

    delete '기사 부스트 취소' do
      tags 'Boosts'
      description '지정된 기사의 부스트를 취소합니다. 인증이 필요합니다.'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :article_id,
                in: :path,
                type: :string,
                required: true,
                description: '기사 slug'

      response '200', '부스트 취소 성공' do
        schema type: :object,
               properties: {
                 boostable_type: { type: :string },
                 boostable_slug: { type: :string },
                 boosted: { type: :boolean },
                 boosts_count: { type: :integer }
               },
               required: %w[boostable_type boostable_slug boosted boosts_count]

        let(:article_id) { articles(:ruby_article).slug }
        let(:Authorization) { auth_token(users(:john)) }

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: %w[error]

        let(:article_id) { articles(:ruby_article).slug }
        let(:Authorization) { nil }

        run_test!
      end
    end
  end

  path '/api/v1/posts/{post_id}/boost' do
    post '포스트 부스트' do
      tags 'Boosts'
      description '지정된 포스트를 부스트(공유)합니다. 인증이 필요합니다.'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :post_id,
                in: :path,
                type: :string,
                required: true,
                description: '포스트 slug'

      response '201', '부스트 생성 성공' do
        schema type: :object,
               properties: {
                 boostable_type: { type: :string },
                 boostable_slug: { type: :string },
                 boosted: { type: :boolean },
                 boosts_count: { type: :integer }
               },
               required: %w[boostable_type boostable_slug boosted boosts_count]

        let(:test_post) do
          Post.create!(
            body: 'swgr boost post',
            user: users(:john),
            post_type: 0,
            status: 1
          )
        end
        let(:post_id) { test_post.slug }
        let(:Authorization) { auth_token(users(:john)) }

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: %w[error]

        let(:post_id) { 'nonexistent-slug' }
        let(:Authorization) { nil }

        run_test!
      end
    end

    delete '포스트 부스트 취소' do
      tags 'Boosts'
      description '지정된 포스트의 부스트를 취소합니다. 인증이 필요합니다.'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :post_id,
                in: :path,
                type: :string,
                required: true,
                description: '포스트 slug'

      response '200', '부스트 취소 성공' do
        schema type: :object,
               properties: {
                 boostable_type: { type: :string },
                 boostable_slug: { type: :string },
                 boosted: { type: :boolean },
                 boosts_count: { type: :integer }
               },
               required: %w[boostable_type boostable_slug boosted boosts_count]

        let(:test_post) do
          Post.create!(
            body: 'swgr unboost post',
            user: users(:john),
            post_type: 0,
            status: 1
          )
        end
        let(:post_id) { test_post.slug }
        let(:Authorization) { auth_token(users(:john)) }

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: %w[error]

        let(:post_id) { 'nonexistent-slug' }
        let(:Authorization) { nil }

        run_test!
      end
    end
  end
end
