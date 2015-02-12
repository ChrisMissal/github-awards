Rails.application.routes.draw do
  root to: "application#welcome"
  
  resources :repositories

  resources :users do
    get 'search', on: :collection
  end
end
