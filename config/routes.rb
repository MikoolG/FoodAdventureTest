# frozen_string_literal: true

Rails.application.routes.draw do
  resources :adventures, only: %i[new create show index] do
    get 'adventure_begins', on: :collection
  end
  
  resources :food_trucks, only: [:index]

  post 'sms/receive', to: 'sms#receive'

  root 'adventures#new'
end
