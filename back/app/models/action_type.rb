class ActionType < ApplicationRecord
  has_many :position_action_types, dependent: :destroy
  has_many :positions, through: :position_action_types
  has_many :actions, dependent: :destroy

  validates :action_type, presence: true, inclusion: { in: %w[prince noble] }
  validates :name, presence: true
  validates :display_params, inclusion: { in: %w[C P C2 PF] }, allow_blank: true
end
