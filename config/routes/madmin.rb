# Below are the routes for madmin
namespace :madmin do
  resources :tags
  resources :articles
  resources :sites
  resources :users
  root to: "dashboard#show"
end
