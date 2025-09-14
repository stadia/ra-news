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
  resources :sites
  resources :users
  root to: "dashboard#show"
end
