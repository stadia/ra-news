# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Articles', type: :request do
  fixtures :articles, :users, :sites, :federails_actors

  def self.article_schema
    {
      type: :object,
      properties: {
        slug: { type: :string },
        title: { type: :string },
        title_ko: { type: :string, nullable: true },
        url: { type: :string },
        host: { type: :string },
        is_related: { type: :boolean },
        likers_count: { type: :integer },
        posts_count: { type: :integer },
        published_at: { type: :string, format: 'date-time', nullable: true },
        created_at: { type: :string, format: 'date-time' },
        updated_at: { type: :string, format: 'date-time' },
        summary_key: { type: :array, items: { type: :string } },
        tags: { type: :array, items: { type: :string } },
        liked: { type: :boolean },
        boosted: { type: :boolean },
        boosts_count: { type: :integer }
      },
      required: %w[slug title url host is_related likers_count posts_count created_at updated_at tags liked boosted boosts_count]
    }
  end

  def self.pagination_schema
    {
      type: :object,
      properties: {
        page: { type: :string, nullable: true, description: 'keyset 페이지네이션 커서 (nullable)' },
        next_page: { type: :string, nullable: true, description: '다음 페이지 keyset 커서' },
        limit: { type: :integer }
      },
      required: %w[limit]
    }
  end

  path '/api/v1/articles' do
    get '기사 목록 조회' do
      tags 'Articles'
      description '확인된(confirmed) 기사 목록을 페이지네이션과 함께 반환합니다.'
      produces 'application/json'
      security []
      parameter name: :search,
                in: :query,
                type: :string,
                required: false,
                description: '검색 키워드 (제목/내용 기반 풀텍스트 검색)'

      response '200', '기사 목록 반환 성공' do
        schema type: :object,
               properties: {
                 articles: { type: :array, items: article_schema },
                 pagination: pagination_schema
               },
               required: %w[articles pagination]

        let(:search) { nil }
        run_test!
      end
    end
  end

  path '/api/v1/articles/others' do
    get '기타 기사 조회' do
      tags 'Articles'
      description '관련(is_related) 기사가 아닌 기사들을 페이지네이션과 함께 반환합니다.'
      produces 'application/json'
      security []

      response '200', '기타 기사 목록 반환 성공' do
        schema type: :object,
               properties: {
                 articles: { type: :array, items: article_schema },
                 pagination: pagination_schema
               },
               required: %w[articles pagination]

        run_test!
      end
    end
  end

  path '/api/v1/articles/tag/{keyword}' do
    get '태그로 기사 조회' do
      tags 'Articles'
      description '특정 태그 키워드가 포함된 기사 목록을 페이지네이션과 함께 반환합니다.'
      produces 'application/json'
      security []
      parameter name: :keyword,
                in: :path,
                type: :string,
                required: true,
                description: '검색할 태그 키워드 (예: ruby, rails)'

      response '200', '태그 기사 목록 반환 성공' do
        let(:keyword) { 'ruby' }
        schema type: :object,
               properties: {
                 articles: { type: :array, items: article_schema },
                 pagination: pagination_schema
               },
               required: %w[articles pagination]

        run_test!
      end
    end
  end
end
