class PositionActionType < ApplicationRecord
  belongs_to :position
  belongs_to :action_type

  validates :position_id, uniqueness: { scope: :action_type_id }
end
