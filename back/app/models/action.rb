class Action < ApplicationRecord
  belongs_to :position
  belongs_to :action_type
  belongs_to :country, optional: true
  belongs_to :second_country, class_name: "Country", optional: true
  belongs_to :province, optional: true

  validates :cycle_number, presence: true
end
