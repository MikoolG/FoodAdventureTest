# frozen_string_literal: true

FactoryBot.define do
  factory :adventure_food_truck do
    order { 0 }
    adventure
    food_truck
  end
end
