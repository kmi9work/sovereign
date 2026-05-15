class CycleChannel < ApplicationCable::Channel
  def subscribed
    stream_from "cycle_global"
  end

  def unsubscribed
  end
end
