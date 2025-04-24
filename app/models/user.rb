class User < ApplicationRecord
  devise :database_authenticatable, :jwt_authenticatable, :recoverable, jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null
end
