class Participant < ApplicationRecord
  belongs_to :event
  belongs_to :student

  after_update :broadcast_presence_change, if: -> { saved_change_to_present? }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id present location]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[event student]
  end

  def broadcast_presence_change
    channel = "presence_channel_#{event_id}"
    payload = {
      id: id,
      present: present,
      location: location
    }

    ActionCable.server.broadcast(channel, payload)
  end

  delegate :name, to: :student, prefix: true
    ransacker :student_name do |parent|
    Arel.sql("LOWER(#{Student.table_name}.name)")
  end
end
