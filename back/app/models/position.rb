class Position < ApplicationRecord
  belongs_to :country
  has_many :position_action_types, dependent: :destroy
  has_many :action_types, through: :position_action_types
  has_many :actions, dependent: :destroy

  validates :name, presence: true
end
