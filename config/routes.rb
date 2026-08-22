Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up", to: "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health", to: "health#index"

      post "register", to: "auth#register"
      post "login", to: "auth#login"
      get "me", to: "auth#me"

      resources :tasks
      resources :categories, only: %i[index show]
    end
  end
end
