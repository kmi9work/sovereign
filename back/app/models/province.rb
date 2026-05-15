class Province < ApplicationRecord
  belongs_to :country
  has_many :actions, dependent: :nullify

  validates :name, presence: true

  def country_name
    country&.name
  end
end
