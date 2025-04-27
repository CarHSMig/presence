# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :course
  has_and_belongs_to_many :class_rooms
  has_many :participants

  validates :name, :description, :event_start, :event_end, :location, :latitude, :longitude, presence: true

  scope :finished, -> { where('event_end < ?', Time.current) }
  scope :upcoming, -> { where('event_start > ?', Time.current) }
  scope :in_progress, -> { where('event_start < ? AND event_end > ?', Time.current, Time.current) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name description event_start event_end location latitude longitude]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[course class_rooms participants]
  end
end
