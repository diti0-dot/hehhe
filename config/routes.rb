Rails.application.routes.draw do
  get "events/index"
  resources :preferred_emails
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  resources :events
  resources :preferred_emails
  root 'events#index'
end
