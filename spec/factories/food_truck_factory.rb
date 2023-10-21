# frozen_string_literal: true

# frozen_string_literal: true

FactoryBot.define do
  factory :food_truck do
    applicant { Faker::Name.unique.name }
    facility_type { ['Truck', 'Push Cart'].sample }
    location_description { Faker::Address.community }
    address { Faker::Address.unique.street_address }
    status { 'APPROVED' }
    food_items { Faker::Food.dish }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    schedule { Faker::Internet.url }
    days_hours do
      "#{Faker::Time.between_dates(from: Date.today - 1, to: Date.today, period: :morning).strftime('%a')}-
                    #{Faker::Time.between_dates(from: Date.today - 1, to: Date.today, period: :morning).strftime('%a')}:
                    #{Faker::Time.between_dates(from: Date.today - 1, to: Date.today,
                                                period: :morning).strftime('%l%P')}-
                    #{Faker::Time.between_dates(from: Date.today - 1, to: Date.today,
                                                period: :evening).strftime('%l%P')}"
    end
    active { [true, false].sample }
  end
end
