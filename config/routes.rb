Rails.application.routes.draw do
  root 'press_threads#index'
  
  resources :press_threads, only: [:index, :show, :create, :destroy] do
    resources :messages, only: [:create]
  end
  
  resources :messages, only: [:update]
  
  resources :gpts, only: [:index, :new, :create, :edit, :update, :destroy]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # LINE Messaging API webhook (secure path)
  post '/line/webhook/:token', to: 'line_bot#webhook'

  # Defines the root path route ("/")
  # root "posts#index"
end
