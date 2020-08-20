Rails.application.routes.draw do
  resources :import
  resources :stories do
    post 'fork', on: :member
  end
  resources :story_formats
  resources :story_passages
  resources :flow

  get 'settings', to: 'settings#edit', as: 'settings'
  patch 'settings', to: 'settings#update'

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  devise_scope :user do
    get 'sign_in', to: 'users/sessions#new'
    get 'sign_up', to: 'users/registrations#new'
    get 'forgot_password', to: 'users/passwords#new'
    get 'reset_password', to: 'users/passwords#edit'
  end

  root to: 'application#home'
  resources :passages do
    post 'fork', on: :member
  end
  get 'formatted_stories/:id', to: 'formatted_story#show', as: 'formatted_stories'
  get 'flows/:id', to: 'flow#edit', as: 'flows'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  # root 'passages#index', as: 'passages_index'
end
