FactoryBot.define do
  factory :adventure do
    phone_number { Faker::Number.number(digits: 10) }
    food_preference { %w[Vegan Asian Tacos Desserts Everything].sample }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    zip_code { Faker::Address.zip }
    number_of_trucks { rand(1..5) }
    adventure_day { Faker::Date.forward(days: 30) } # Random date within next 30 days
    adventure_start_time { Faker::Time.forward(days: 30, period: :morning) } # Random time within next 30 days
    status { Adventure.statuses.keys.sample } # Random status from defined enum

    after(:create) do |adventure|
      create(:adventure_food_truck, adventure:, food_truck: create(:food_truck))
    end
  end
end
