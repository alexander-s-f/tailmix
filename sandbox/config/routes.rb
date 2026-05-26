Rails.application.routes.draw do
  mount Lookbook::Engine, at: "/lookbook"
  mount Tailmix::Engine, at: "/tailmix"
  
  root "pages#dashboard"
  get "/leads" => "pages#leads"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
