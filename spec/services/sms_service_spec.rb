require 'rails_helper'

RSpec.describe SmsService do
  describe '.send_sms' do
    let(:twilio_client) { instance_double(Twilio::REST::Client) }
    let(:messages) { instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList) }
    let(:phone_number) { '+1234567890' }
    let(:message_body) { 'Test message' }

    before do
      allow(TwilioClient).to receive(:client).and_return(twilio_client)
      allow(twilio_client).to receive(:messages).and_return(messages)
    end

    it 'sends an SMS message' do
      expect(messages).to receive(:create).with(
        from: Rails.application.credentials.dig(:twilio, :phone_number),
        to: phone_number,
        body: message_body
      )
      SmsService.send_sms(phone_number, message_body)
    end
  end
end
