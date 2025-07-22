Rails.application.routes.draw do
  get "events/index"
  resources :preferred_emails
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  resources :events
  resources :preferred_emails
  post '/webhooks/gmail_notification', to: 'webhooks#gmail_notification'
  root 'events#index'
end
