class AdventureFoodTruck < ApplicationRecord
  belongs_to :adventure
  belongs_to :food_truck

  validates :order, uniqueness: { scope: :adventure_id }
end
