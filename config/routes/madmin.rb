# Below are the routes for madmin
namespace :madmin do
  resources :preferences
  resources :comments
  resources :tags
  resources :articles do
    member do
      put :discard
      put :restore
    end
  end
  resources :sites do
    member do
      put :discard
      put :restore
    end
  end
  resources :users
  resources :roles

  # Social 메뉴 - OAuth 인증
  get "social", to: "social#index", as: :social_index

  root to: "dashboard#show"
end
