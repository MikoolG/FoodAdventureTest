# frozen_string_literal: true

FactoryBot.define do
  factory :food_truck do
    applicant { 'Test Applicant' }
    facility_type { 'Push Cart' }
    location_description { 'Test Location' }
    address { '123 Test St' }
    status { 'APPROVED' }
    food_items { 'Hot Dogs' }
    latitude { 37.7749 }
    longitude { -122.4194 }
    schedule { 'http://test.com/schedule' }
    days_hours { 'Mon-Fri: 9am-5pm' }
    active { true }
  end
end
