class User < ApplicationRecord
  belongs_to :student, optional: true

  devise :database_authenticatable, :jwt_authenticatable, :recoverable, jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null
end
