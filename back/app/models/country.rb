class Country < ApplicationRecord
  has_many :provinces, dependent: :destroy
  has_many :positions, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
