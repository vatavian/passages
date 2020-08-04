Rails.application.routes.draw do
  resources :import
  resources :stories
  resources :story_formats
  resources :story_passages

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
  resources :passages
  get 'formatted_stories/:id', to: 'formatted_story#show', as: 'formatted_stories'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  # root 'passages#index', as: 'passages_index'
end
