Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  draw :madmin

  resources :passwords, param: :token
  resources :articles, only: %i[index show new create] do
    resources :comments, only: %i[create destroy]
  end

  get "others" => "articles#others"

  resource :users, only: %i[edit update destroy]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  get "rss" => "home#rss", as: :rss

  get "login" => "sessions#new", as: :new_session
  post "login" => "sessions#create", as: :session
  get "logout" => "sessions#destroy", as: :logout

  get "signup" => "users#new", as: :new_user
  post "signup" => "users#create", as: :user

  get "social/:provider/authorize", to: "social#provider_authorize", as: :social_provider_authorize
  get "social/:provider/callback", to: "social#provider_callback", as: :social_provider_callback

  mount MissionControl::Jobs::Engine, at: "/jobs"
end
