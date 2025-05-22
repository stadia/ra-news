class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @articles = Article.where(deleted_at: nil).limit(9).order(created_at: :desc)
  end
end
