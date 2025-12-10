Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: 'users/sessions' }

  namespace :users do
    get 'current_user', to: 'users#show'
  end

  patch '/participants/:event_id/confirm_presence', to: 'participants#confirm_presence',
                                                    as: :confirm_presence_participants
  get '/participants/:event_id', to: 'participants#show_event', as: :show_event_participants

  namespace :students do
    resources :events
  end

  namespace :admin do
    resources :courses
    resources :events do
      resources :participants, only: %i[index show update destroy] do
        collection do
          get :export_participants
        end
      end
      collection do
        get :classrooms_by_courses
      end
    end
    resources :courses do
      resources :class_rooms do
        collection do
          post :batch
        end
        resources :students do
          collection do
            post :import
            get :template
          end
          member do
            delete :delete_embedding
            post :add_embedding
          end
        end
      end
    end
  end

  get 'up' => 'rails/health#show', as: :rails_health_check

  mount ActionCable.server => '/cable'
end
