Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  draw :madmin

  devise_for :users, path: "", path_names: {
    sign_in: "login", sign_out: "logout", sign_up: "signup",
    password: "passwords", registration: "account"
  }, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords",
    confirmations: "users/confirmations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  devise_scope :user do
    get "account/password", to: "users/registrations#password", as: :account_password
    get "account/oauth-signup", to: "users/oauth_registrations#new", as: :new_user_oauth_registration
    post "account/oauth-signup", to: "users/oauth_registrations#create", as: :user_oauth_registration
  end

  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :refresh, to: "tokens#refresh"
      end

      resources :articles, only: %i[index] do
        collection do
          get :others
          get "tag/:keyword", action: :tag, as: :tag, format: false, constraints: { keyword: /[^\/]+/ }
        end
      end
    end
  end

  resource :push_subscription, only: %i[ create destroy ]
  resources :posts, only: [ :show, :create ] do
    resource :like, only: [ :create, :destroy ], controller: :likes, defaults: { likeable_type: "Post" }
    resource :boost, only: [ :create, :destroy ], controller: :boosts, defaults: { boostable_type: "Post" }
  end
  resources :articles, only: %i[index show new create] do
    resource :like, only: [ :create, :destroy ], controller: :likes, defaults: { likeable_type: "Article" }
    resource :boost, only: [ :create, :destroy ], controller: :boosts, defaults: { boostable_type: "Article" }
    resources :posts, only: %i[create destroy]
  end

  get "others" => "articles#others"
  get "tag/:keyword" => "articles#tag", as: :tag, format: false, constraints: { keyword: /[^\/]+/ }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  get "rss"            => "home#rss",            as: :rss
  get "about"          => "home#about",          as: :about
  get "privacy-policy" => "home#privacy_policy", as: :privacy_policy
  get "terms"          => "home#terms",          as: :terms

  get "social/:provider/authorize", to: "social#provider_authorize", as: :social_provider_authorize
  get "social/:provider/callback", to: "social#provider_callback", as: :social_provider_callback

  # Discord
  get "discord/oauth/callback", to: "discord#callback",  as: :discord_oauth_callback

  get "slack/oauth/callback", to: "slack#callback", as: :slack_oauth_callback
  post "slack/events", to: "slack#events", as: :slack_events

  get ":provider/install", to: "oauth#install", as: :oauth_install
  get ":provider/result", to: "oauth#result", as: :oauth_result

  # Public user profiles at /@username (also used as ActivityPub profile_url)
  # 1. 실제 요청을 처리할 내부 라우트 (컨트롤러 연결)
  get "/@:username", to: "profiles#show", as: :user_profile_base, format: false, constraints: { username: /[^\/]+/ }
  get "/@:username/followers", to: "profiles#followers", as: :user_profile_followers, format: false, constraints: { username: /[^\/]+/ }
  get "/@:username/following", to: "profiles#following", as: :user_profile_following, format: false, constraints: { username: /[^\/]+/ }
  get "/@:username/posts",    to: "profiles#posts",    as: :user_profile_posts, format: false, constraints: { username: /[^\/]+/ }
  get "/@:username/comments", to: "profiles#comments", as: :user_profile_comments, format: false, constraints: { username: /[^\/]+/ }
  get "/@:username/likes",    to: "profiles#likes",    as: :user_profile_likes, format: false, constraints: { username: /[^\/]+/ }
  get "/@:username/boosts",   to: "profiles#boosts",   as: :user_profile_boosts, format: false, constraints: { username: /[^\/]+/ }
  # 2. 헬퍼 메서드 오버라이드 (URL 생성 로직)
  direct :user_profile do |user|
    # user 객체에서 username을 뽑아 위에서 정의한 경로로 보냅니다.
    route_for(:user_profile_base, username: (user.is_a?(Array) ? user.first : user).username)
  end

  constraints AuthenticatedConstraint.new do
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  # Federails client 대체 라우트
  resources :followings, only: [ :new, :create, :destroy ] do
    collection do
      post :follow
    end
    member do
      put :accept
    end
  end

  resources :actors, only: [ :show ] do
    collection do
      get :lookup
    end
  end

  get "/feed", to: "activities#feed", as: :feed

  mount Federails::Engine => "/"
end
