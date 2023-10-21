require 'rails_helper'

RSpec.describe FoodTruck, type: :model do
  subject { build(:food_truck) }  # assuming you have a factory defined for food_trucks

  describe 'validations' do
    it { should validate_presence_of(:applicant) }
    it { should validate_presence_of(:facility_type) }
    it { should validate_presence_of(:address) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:latitude) }
    it { should validate_presence_of(:longitude) }
    it { should validate_uniqueness_of(:applicant) }
    it { should validate_length_of(:applicant).is_at_most(255) }
    it { should validate_length_of(:address).is_at_most(255) }

    context 'when expiration date is in the future' do
      it 'is valid' do
        subject.expiration_date = 1.day.from_now
        expect(subject).to be_valid
      end
    end
  end

  describe '#normalize_applicant_name' do
    it 'titleizes the applicant name' do
      subject.applicant = 'john doe'
      subject.save
      expect(subject.reload.applicant).to eq('John Doe')
    end
  end

  describe '.active' do
    it 'returns only active food trucks' do
      active_truck = create(:food_truck, active: true)
      inactive_truck = create(:food_truck, applicant: 'Unique Applicant', active: false)
      expect(described_class.active).to contain_exactly(active_truck)
    end
  end

  describe '#expired?' do
    let(:food_truck) { create(:food_truck, expiration_date: expiration_date) }

    context 'when expiration date is in the past' do
      let(:expiration_date) { 2.days.ago }

      it 'returns true' do
        expect(food_truck.expired?).to eq(true)
      end
    end

    context 'when expiration date is today' do
      let(:expiration_date) { Date.today }

      it 'returns false' do
        expect(food_truck.expired?).to eq(false)
      end
    end

    context 'when expiration date is in the future' do
      let(:expiration_date) { Date.tomorrow }

      it 'returns false' do
        expect(food_truck.expired?).to eq(false)
      end
    end
  end
end
