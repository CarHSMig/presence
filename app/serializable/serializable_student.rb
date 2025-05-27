class SerializableStudent < JSONAPI::Serializable::Resource
  type :students

  attributes :name, :ra, :class_room_id, :email

  belongs_to :class_room
  has_many :participants

  attribute :email do
    @object.user&.email
  end
end
