# frozen_string_literal: true

class SerializableClassRoom < JSONAPI::Serializable::Resource
  type :class_rooms

  attributes :name, :period

  attribute :course do
    {
      id: @object.course.id,
      name: @object.course.name,
      periods: @object.course.periods
    }
  end

  belongs_to :course
  has_many :students
  has_many :events
end
