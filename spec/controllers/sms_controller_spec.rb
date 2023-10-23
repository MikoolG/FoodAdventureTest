# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SmsController, type: :controller do
  describe '#receive' do
    let(:phone_number) { '1234567890' }

    context 'when adventure is not found' do
      before do
        allow(Adventure).to receive(:find_by).and_return(nil)
        allow(SmsService).to receive(:send_sms)
      end

      it 'sends a message about no active adventure and returns' do
        post :receive, params: { 'Body' => 'next', 'From' => phone_number }
        expect(SmsService).to have_received(:send_sms).with(
          phone_number,
          "🕵️ Oops! It seems like there's no active adventure linked to this number. Craving some culinary quests? Head over to [FoodTruckAdventure.com](https://foodtruckadventure.com) to cook up a new Food Truck Adventure! 🚚🌮"
        )
      end
    end

    context 'when adventure is found' do
      let(:adventure) { instance_double(Adventure) }
      let(:response) { { message: 'Next stop message' } }

      before do
        allow(Adventure).to receive(:find_by).and_return(adventure)
        allow(SmsService).to receive(:process_command).and_return(response)
        allow(SmsService).to receive(:send_sms)
      end

      it 'processes the command and sends a response message' do
        post :receive, params: { 'Body' => 'next', 'From' => phone_number }
        expect(SmsService).to have_received(:process_command).with(adventure, 'next')
        expect(SmsService).to have_received(:send_sms).with(phone_number, 'Next stop message')
      end
    end
  end
end
