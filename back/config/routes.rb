Rails.application.routes.draw do
  # Action Cable WebSocket endpoint
  mount ActionCable.server => '/cable'

  namespace :api do
    namespace :v1 do
      resources :countries, only: %i[index show create update destroy] do
        collection do
          get :with_positions
        end
        # GET /api/v1/countries/:country_id/positions — positions with action types
        resources :positions, only: [:index]
        # GET /api/v1/countries/:country_id/actions/current_cycle
        resources :actions, only: [] do
          collection do
            get :current_cycle
          end
        end
      end

      # resources :provinces, only: %i[index show create update destroy]

      resources :positions, only: %i[index show create update destroy]

      resources :action_types, only: %i[index show create update destroy] do
        member do
          get :with_lists
        end
      end

      # POST /api/v1/actions/perform
      resources :actions, only: %i[index show destroy] do
        collection do
          post :perform
        end
        member do
          patch :mark_read
        end
      end

      resources :parameters, only: %i[index show update] do
        collection do
          post :next_cycle
          post :prev_cycle
        end
      end
    end
  end
end
