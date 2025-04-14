class PresenceChannel < ApplicationCable::Channel
  def subscribed
    event_id = params[:event_id]
    stream_from "presence_channel_#{event_id}"
  end
end
