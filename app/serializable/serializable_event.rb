# frozen_string_literal: true

class SerializableEvent < JSONAPI::Serializable::Resource
  type :event

  attributes :id, :name, :description, :event_start, :event_end, :location_optional, :face_auth, :location, :latitude, :longitude, :creator_id

  has_many :courses
  has_many :class_rooms
  has_many :participants
  has_one :creator
end
