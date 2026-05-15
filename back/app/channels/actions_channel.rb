class ActionsChannel < ApplicationCable::Channel
  def subscribed
    country_id = params[:country_id]
    stream_from "actions_#{country_id}"
  end

  def unsubscribed
  end
end
