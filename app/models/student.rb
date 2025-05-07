# frozen_string_literal: true

class Student < ApplicationRecord
  belongs_to :class_room
  has_one :user
  has_many :participants

  validates :name, :ra, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name ra]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[class_room participants]
  end
end
