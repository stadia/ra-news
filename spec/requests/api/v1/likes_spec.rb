# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Likes', type: :request do
  fixtures :users, :articles, :sites, :federails_actors

  # Helper to get a valid JWT
  def auth_token(user)
    post api_v1_auth_login_path, params: { user: { email: user.email, password: 'password' } }, as: :json
    response.headers['Authorization']
  end

  path '/api/v1/articles/{article_id}/like' do
    post '기사 좋아요' do
      tags 'Likes'
      description '지정된 기사에 좋아요를 추가합니다. 인증이 필요합니다.'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :article_id,
                in: :path,
                type: :string,
                required: true,
                description: '기사 slug'

      response '201', '좋아요 생성 성공' do
        schema type: :object,
               properties: {
                 likeable_type: { type: :string },
                 likeable_slug: { type: :string },
                 liked: { type: :boolean },
                 likes_count: { type: :integer }
               },
               required: %w[likeable_type likeable_slug liked likes_count]

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

    delete '기사 좋아요 취소' do
      tags 'Likes'
      description '지정된 기사의 좋아요를 취소합니다. 인증이 필요합니다.'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :article_id,
                in: :path,
                type: :string,
                required: true,
                description: '기사 slug'

      response '200', '좋아요 취소 성공' do
        schema type: :object,
               properties: {
                 likeable_type: { type: :string },
                 likeable_slug: { type: :string },
                 liked: { type: :boolean },
                 likes_count: { type: :integer }
               },
               required: %w[likeable_type likeable_slug liked likes_count]

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

  path '/api/v1/posts/{post_id}/like' do
    post '포스트 좋아요' do
      tags 'Likes'
      description '지정된 포스트에 좋아요를 추가합니다. 인증이 필요합니다.'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :post_id,
                in: :path,
                type: :string,
                required: true,
                description: '포스트 slug'

      response '201', '좋아요 생성 성공' do
        schema type: :object,
               properties: {
                 likeable_type: { type: :string },
                 likeable_slug: { type: :string },
                 liked: { type: :boolean },
                 likes_count: { type: :integer }
               },
               required: %w[likeable_type likeable_slug liked likes_count]

        let(:test_post) do
          Post.create!(
            body: 'swgr test post',
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

    delete '포스트 좋아요 취소' do
      tags 'Likes'
      description '지정된 포스트의 좋아요를 취소합니다. 인증이 필요합니다.'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :post_id,
                in: :path,
                type: :string,
                required: true,
                description: '포스트 slug'

      response '200', '좋아요 취소 성공' do
        schema type: :object,
               properties: {
                 likeable_type: { type: :string },
                 likeable_slug: { type: :string },
                 liked: { type: :boolean },
                 likes_count: { type: :integer }
               },
               required: %w[likeable_type likeable_slug liked likes_count]

        let(:test_post) do
          Post.create!(
            body: 'swgr unlike post',
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
