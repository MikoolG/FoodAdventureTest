# frozen_string_literal: true

class AdventureFoodTruck < ApplicationRecord
  belongs_to :adventure
  belongs_to :food_truck

  validates :order, uniqueness: { scope: :adventure_id }
  validates :order, numericality: { only_integer: true }
  validates :adventure, :food_truck, presence: true

  scope :ordered, -> { order(:order) }
end
