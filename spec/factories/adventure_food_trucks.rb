FactoryBot.define do
  factory :adventure_food_truck do
    order { 0 }  # Default order is 0
    adventure
    food_truck
  end
end
