class SerializableStudent < JSONAPI::Serializable::Resource
  type :students

  attributes :name, :ra, :class_room_id, :email, :embedding_images

  belongs_to :class_room
  has_many :participants

  attribute :email do
    @object.user&.email
  end

  attribute :embedding_images do
    embeddings = FaceAuth::GetStudentEmbeddings.new(@object.id).perform
    
    if embeddings.present? && embeddings['images'].present?
      embeddings['images'].map do |image|
        {
          id: image['id'],
          image_url: image['image_url']
        }
      end
    else
      []
    end
  end
end
