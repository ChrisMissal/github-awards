Rails.application.routes.draw do
  root to: "application#welcome"
  
  get "about" => "application#about"
  
  resources :repositories

  resources :users do
    get 'search', on: :collection
  end
end
