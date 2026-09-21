Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resource :registrierung, only: %i[new create]
  resource :sitzung, only: %i[new create destroy]
  resource :profil, controller: "profil", only: %i[show edit update]

  # "benutzer" ist uncountable (siehe config/initializers/inflections.rb) — ein
  # resources :benutzer würde für index und show denselben Route-Namen
  # (admin_benutzer_path) erzeugen und kollidieren, daher explizite Routen.
  namespace :admin do
    get "benutzer", to: "benutzer#index", as: :benutzer
    get "benutzer/:id", to: "benutzer#show", as: :benutzer_zeigen
  end

  # "zeitfenster" ist ebenfalls uncountable (siehe oben), gleiche Lösung.
  # reservierungen/wartelisten sind korrekt dekliniert, daher normale
  # resources; zeitfenster_id wird als Formularfeld statt als verschachtelte
  # Route übergeben.
  get "zeitfenster", to: "zeitfenster#index", as: :zeitfenster
  get "zeitfenster/:id", to: "zeitfenster#show", as: :zeitfenster_zeigen

  resources :reservierungen, only: %i[index create destroy]
  resources :wartelisten, only: :create

  # Defines the root path route ("/")
  root "seiten#start"
end
