class Parameter < ApplicationRecord
  validates :current_cycle, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  after_update :broadcast_cycle_update, if: :saved_change_to_current_cycle?

  private

  def broadcast_cycle_update
    ActionCable.server.broadcast("cycle_global", {
      type: "cycle_update",
      current_cycle: current_cycle
    })
  end
end
