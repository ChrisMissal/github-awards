Rails.application.routes.draw do
  root to: "users#index"
  
  resources :repositories

  resources :users do
    get 'search', on: :collection
  end
end
