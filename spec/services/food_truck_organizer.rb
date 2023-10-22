require 'rails_helper'

RSpec.describe FoodTruckOrganizer, type: :service do
  # 94102 is the zip code for San Francisco, CA => 37.77939,-122.41774
  let(:adventure) do
    create(:adventure, zip_code: 94_102, food_preference: 'Pizza', number_of_trucks: 2)
  end
  let!(:food_truck_near) do
    create(:food_truck, applicant: 'near', latitude: 37.7789, longitude: -122.4199, food_items: 'Pizza')
  end
  let!(:food_truck_medium) do
    create(:food_truck, applicant: 'medium', latitude: 37.7751, longitude: -122.4195, food_items: 'Pizza')
  end
  let!(:food_truck_far) do
    create(:food_truck, applicant: 'far', latitude: 37.8000, longitude: -122.4300, food_items: 'Pizza')
  end
  let!(:food_truck_different_food) do
    create(:food_truck, latitude: 37.7755, longitude: -122.4195, food_items: 'Burger')
  end

  subject { described_class.new(adventure) }

  describe '#organize' do
    it 'returns food trucks based on proximity and food preference' do
      expected_order = [food_truck_near, food_truck_medium]
      result = subject.organize

      expect(result.first).to eq(food_truck_near)
    end

    it 'does not return trucks with different food preferences' do
      result = subject.organize

      expect(result).not_to include(food_truck_different_food)
    end

    it 'respects the number of trucks requested by the user' do
      result = subject.organize

      expect(result.count).to eq(adventure.number_of_trucks)
    end
  end
end
