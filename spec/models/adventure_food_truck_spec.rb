require 'rails_helper'

RSpec.describe AdventureFoodTruck, type: :model do
  describe 'associations' do
    it { should belong_to(:adventure) }
    it { should belong_to(:food_truck) }
  end

  describe 'validations' do
    it { should validate_presence_of(:adventure) }
    it { should validate_presence_of(:food_truck) }
    it { should validate_numericality_of(:order).only_integer }
  end

  describe 'order scope' do
    let!(:adventure) { create(:adventure) }
    let!(:food_truck_1) { create(:food_truck) }
    let!(:food_truck_2) { create(:food_truck) }
    let!(:aft_1) { AdventureFoodTruck.create(adventure:, food_truck: food_truck_1, order: 2) }
    let!(:aft_2) { AdventureFoodTruck.create(adventure:, food_truck: food_truck_2, order: 1) }

    it 'returns adventure_food_trucks in order' do
      expect(AdventureFoodTruck.ordered).to eq([aft_2, aft_1])
    end
  end
end
