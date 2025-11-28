# frozen_string_literal: true

class Student < ApplicationRecord
  belongs_to :class_room
  has_one :user
  has_many :participants
  has_many :facial_profiles, dependent: :destroy

  validates :name, :ra, presence: true
  validates :ra, uniqueness: { scope: :class_room_id, message: 'já está em uso nesta turma' }
  validates :name, uniqueness: { scope: :class_room_id, message: 'já está em uso nesta turma' }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name ra]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[class_room participants facial_profiles]
  end
end
