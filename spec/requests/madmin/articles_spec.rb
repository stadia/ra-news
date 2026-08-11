# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Madmin::Articles', type: :request do
  include Devise::Test::IntegrationHelpers

  fixtures :users, :articles, :sites, :federails_actors

  let(:admin) { users(:admin) }
  let(:article) { articles(:ruby_article) }

  before { sign_in admin }

  # Madmin::Engine은 isolate_namespace이므로 `madmin_*_path` 헬퍼가
  # 자동으로 제공되지 않는다. Madmin::ApplicationController에서 메인 앱
  # url_helpers를 include하지 않으면 아래 리다이렉트가 NameError로 깨진다.
  describe 'PUT /madmin/articles/:id/discard' do
    it '기사를 폐기하고 상세 페이지로 리다이렉트한다' do
      put discard_madmin_article_path(article)

      expect(response).to redirect_to(madmin_article_path(article))
      expect(article.reload).to be_discarded
    end
  end

  describe 'PUT /madmin/articles/:id/restore' do
    before { article.discard }

    it '기사를 복원하고 상세 페이지로 리다이렉트한다' do
      put restore_madmin_article_path(article)

      expect(response).to redirect_to(madmin_article_path(article))
      expect(article.reload).not_to be_discarded
    end
  end

  describe 'PUT /madmin/articles/:id/mark_unrelated' do
    it '관련 없음으로 표시하고 상세 페이지로 리다이렉트한다' do
      put mark_unrelated_madmin_article_path(article)

      expect(response).to redirect_to(madmin_article_path(article))
      expect(article.reload.is_related).to be(false)
    end
  end

  describe 'PUT /madmin/articles/:id/reprocess' do
    it '폐기된 기사는 재처리하지 않고 상세 페이지로 리다이렉트한다' do
      article.discard

      put reprocess_madmin_article_path(article)

      expect(response).to redirect_to(madmin_article_path(article))
    end
  end

  describe 'PUT /madmin/articles/:id/regenerate_thumbnail' do
    it '썸네일 재생성을 요청하고 상세 페이지로 리다이렉트한다' do
      put regenerate_thumbnail_madmin_article_path(article)

      expect(response).to redirect_to(madmin_article_path(article))
    end
  end
end
