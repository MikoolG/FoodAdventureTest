# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FoodTruckOrganizer, type: :service do
    let(:adventure) do
        create(:adventure, zip_code: 94_102, food_preference: 'Pizza', number_of_trucks: 2)
    end
    let!(:food_truck_near) do
        create(:food_truck, applicant: 'near', latitude: 37.7789, longitude: -122.4199, food_items: 'Pizza', categories: ['Pizza'])
    end
    let!(:food_truck_medium) do
        create(:food_truck, applicant: 'medium', latitude: 37.7751, longitude: -122.4195, food_items: 'Pizza', categories: ['Pizza'])
    end
    let!(:food_truck_far) do
        create(:food_truck, applicant: 'far', latitude: 37.8000, longitude: -122.4300, food_items: 'Pizza', categories: ['Pizza'])
    end
    let!(:food_truck_different_food) do
        create(:food_truck, latitude: 37.7755, longitude: -122.4195, food_items: 'Burger', categories: ['Burger'])
    end

  subject { described_class.new(adventure) }

  describe '#organize' do
    before do
      subject.organize
    end

    it 'creates AdventureFoodTruck records based on proximity and food preference' do
      records = AdventureFoodTruck.where(adventure: adventure).order(:order)
      
      expect(records.first.food_truck).to eq(food_truck_near)
      expect(records.last.food_truck).to eq(food_truck_medium)
    end

    it 'does not create AdventureFoodTruck records for trucks with different food preferences' do
      records = AdventureFoodTruck.where(adventure: adventure)
      
      food_truck_ids = records.map(&:food_truck_id)
      expect(food_truck_ids).not_to include(food_truck_different_food.id)
    end

    it 'creates the number of AdventureFoodTruck records as requested by the user' do
      records = AdventureFoodTruck.where(adventure: adventure)
      
      expect(records.count).to eq(adventure.number_of_trucks)
    end
  end
end
