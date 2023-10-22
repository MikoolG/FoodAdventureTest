require 'rails_helper'

RSpec.describe Adventure, type: :model do
  it { should validate_presence_of(:phone_number) }
  it { should validate_presence_of(:food_preference) }
  it { should validate_presence_of(:city) }
  it { should validate_presence_of(:state) }
  it { should validate_presence_of(:zip_code) }
  it { should validate_presence_of(:number_of_trucks) }
  it { should validate_presence_of(:adventure_day) }
  it { should validate_presence_of(:adventure_start_time) }

  it { should have_many(:adventure_food_trucks).dependent(:destroy) }
  it { should have_many(:food_trucks).through(:adventure_food_trucks) }

  it { should allow_value('1234567890').for(:phone_number) }
  it { should_not allow_value('123456789').for(:phone_number) }

  it { should validate_length_of(:state).is_equal_to(2) }

  it { should allow_value('12345').for(:zip_code) }
  it { should allow_value('12345-6789').for(:zip_code) }
  it { should_not allow_value('1234').for(:zip_code) }

  it { should validate_numericality_of(:number_of_trucks).is_greater_than_or_equal_to(1) }
  it { should_not allow_value(0).for(:number_of_trucks) }
  it {
    should define_enum_for(:status).with_values(awaiting_start: 0, in_progress: 1, complete: 2, stopped: 3,
                                                abandoned: 4)
  }

  describe 'callbacks' do
    let(:adventure) { create(:adventure, status: 'in_progress') }

    it 'clears phone_number when status changes to complete, stopped, or abandoned' do
      %w[complete stopped abandoned].each do |final_status|
        adventure.update(status: final_status)
        expect(adventure.reload.phone_number).to be_nil
      end
    end

    it 'schedules an SMS job when created with awaiting_start status' do
      adventure = build(:adventure, status: 'awaiting_start')
      expect do
        adventure.save
      end.to have_enqueued_job(AdventureJob).with(adventure.id)
    end
  end

  describe 'trucking methods' do
    let(:adventure) { create(:adventure) }
    let(:food_trucks) { create_list(:food_truck, 3) }

    before do
      food_trucks.each_with_index do |food_truck, index|
        AdventureFoodTruck.create(adventure:, food_truck:, order: index)
      end
    end

    it '#next_truck returns the correct food truck' do
      expect(adventure.next_truck).to eq(food_trucks.first)
    end

    it '#advance_to_next_truck! updates the current_truck_index' do
      expect { adventure.advance_to_next_truck! }.to change { adventure.reload.current_truck_index }.by(1)
    end

    it '#on_last_truck? returns true when on last truck' do
      adventure.update!(current_truck_index: 2)
      expect(adventure.on_last_truck?).to be_truthy
    end

    it '#on_last_truck? returns false when not on last truck' do
      expect(adventure.on_last_truck?).to be_falsey
    end

    it '#advance_to_next_truck! does nothing when no next truck' do
      adventure.update!(current_truck_index: 3)  # Assumes there are only 3 trucks
      expect { adventure.advance_to_next_truck! }.not_to(change { adventure.reload.current_truck_index })
    end
  end
  describe '#process_next_truck' do
    let(:adventure) { create(:adventure, status: 'in_progress') }
    let(:food_truck) { create(:food_truck) }

    before do
      AdventureFoodTruck.create(adventure:, food_truck:, order: 0)
    end

    context 'when there is a next truck' do
      it 'returns a message with the next truck details' do
        result = adventure.process_next_truck
        expected_message = "🚚 Vroom, vroom! #{food_truck.applicant} is your next stop at #{food_truck.address}. Get ready for some tasty treats!"
        expect(result[:message]).to eq(expected_message)
        expect(result[:status]).to be_nil
      end
    end

    context 'when there are no more trucks' do
      it 'updates the adventure status to complete and returns a completion message' do
        adventure.update!(current_truck_index: 1)
        result = adventure.process_next_truck
        expected_message = '🎉 Congratulations on completing your Food Truck Adventure! 🚚💨 You’ve tasted the best bites in town and lived to tell the tale. 🍔🌮🍕 Here’s to many more tasty trails! 🥂'
        expect(result[:message]).to eq(expected_message)
        expect(result[:status]).to eq(:complete)
        expect(adventure.reload.status).to eq('complete')
      end
    end
  end

  describe '#stop' do
    let(:adventure) { create(:adventure, status: 'in_progress') }

    it 'updates the adventure status to stopped' do
      adventure.stop
      expect(adventure.reload.status).to eq('stopped')
    end
  end

  describe '#complete' do
    let(:adventure) { create(:adventure, status: 'in_progress') }

    it 'updates the adventure status to complete' do
      adventure.complete
      expect(adventure.reload.status).to eq('complete')
    end
  end

  describe 'geocoding', vcr: { cassette_name: 'geocoding' } do
    let(:adventure) { build(:adventure, zip_code: '89101') }
  
    it 'geocodes the adventure based on its zip code' do
      adventure.save
      expect(adventure.latitude).not_to be_nil
      expect(adventure.longitude).not_to be_nil
    end
  end
end
