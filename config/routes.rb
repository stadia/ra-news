Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  draw :madmin

  resources :passwords, param: :token
  resource :push_subscription, only: %i[ create destroy ]
  resources :articles, only: %i[index show new create] do
    resources :comments, only: %i[create destroy] do
    end
  end

  resources :memos, only: %i[index show new create destroy] do
    resources :comments, only: %i[create destroy], controller: "memo_comments" do
      member do
        post :verify_password
      end
    end
  end

  get "others" => "articles#others"

  resource :users, path: :account do
    member do
      get :password
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  get "rss"   => "home#rss",   as: :rss
  get "about" => "home#about", as: :about

  get "login" => "sessions#new", as: :new_session
  post "login" => "sessions#create", as: :session
  get "logout" => "sessions#destroy", as: :logout

  get "signup" => "users#new", as: :new_user
  post "signup" => "users#create", as: :user

  get "social/:provider/authorize", to: "social#provider_authorize", as: :social_provider_authorize
  get "social/:provider/callback", to: "social#provider_callback", as: :social_provider_callback

  # Public user profiles at /@username (also used as ActivityPub profile_url)
  # 1. 실제 요청을 처리할 내부 라우트 (컨트롤러 연결)
  get "/@:username", to: "profiles#show", as: :user_profile_base
  # 2. 헬퍼 메서드 오버라이드 (URL 생성 로직)
  direct :user_profile do |user|
    # user 객체에서 username을 뽑아 위에서 정의한 경로로 보냅니다.
    route_for(:user_profile_base, username: (user.is_a?(Array) ? user.first : user).username)
  end

  constraints AuthenticatedConstraint.new do
    mount MissionControl::Jobs::Engine, at: "/jobs"
    mount PgReports::Engine, at: "/pg_reports"
  end

  mount Federails::Engine => "/"
end
