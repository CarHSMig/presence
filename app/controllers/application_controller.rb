class ApplicationController < ActionController::API
  include ActiveModel::Model
  include Pundit

  def find_params
    params.require(:id)
  end

  def authenticate_user_with_jwt
    return if current_user

    render json: { error: 'Você precisa estar autenticado para acessar esta rota.' }, status: :unauthorized
  end

  def include_options
    params.slice(:include).as_json.deep_symbolize_keys[:include]
  end
end
