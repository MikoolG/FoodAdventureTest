Rails.application.routes.draw do
  resources :adventures, only: %i[new create show]
  resources :food_trucks, only: [:index]

  root 'adventures#new'
end
