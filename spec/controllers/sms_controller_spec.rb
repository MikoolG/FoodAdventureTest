# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SmsController, type: :controller do
  before do
    allow(controller).to receive(:validate_twilio_request).and_return(true)
  end

  describe '#receive' do
    let(:phone_number) { '2095646978' }

    context 'when adventure is not found' do
      before do
        allow(Adventure).to receive(:find_by).and_return(nil)
        allow(SmsService).to receive(:send_sms)
      end

      it 'sends a message about no active adventure and returns' do
        post :receive, params: { 'Body' => 'next', 'From' => phone_number }
        expect(SmsService).to have_received(:send_sms).with(
          phone_number,
          "🕵️ Oops! It seems like there's no active adventure linked to this number #{phone_number}. Craving some culinary quests? Head over to https://food-truck-adventure-222aa5bc5600.herokuapp.com/ to cook up a new Food Truck Adventure! 🚚🌮"
        )
      end
    end
  end
end
