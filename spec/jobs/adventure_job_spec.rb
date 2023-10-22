require 'rails_helper'

RSpec.describe AdventureJob, type: :job do
  include ActiveJob::TestHelper

  let(:adventure) { create(:adventure, :with_food_truck) }
  let(:sms_service) { instance_double(SmsService) }

  before do
    allow(SmsService).to receive(:send_sms).and_return(true)
  end

  describe '#perform' do
    it 'sends an SMS to start the adventure' do
      expect(SmsService).to receive(:send_sms).with(
        adventure.phone_number,
        "🎉 Your Food Truck Adventure has begun! First stop: #{adventure.next_truck.applicant} at #{adventure.next_truck.address}. Let's roll! 🚚 Type 'next' when you're ready for the next stop, or 'stop' to end your adventure."
      )
      perform_enqueued_jobs do
        described_class.perform_later(adventure.id)
      end
    end
  end
end
