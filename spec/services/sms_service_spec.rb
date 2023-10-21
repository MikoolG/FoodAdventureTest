require 'rails_helper'

RSpec.describe SmsService do
  let(:adventure) do
    instance_double(Adventure, process_next_truck: { message: 'some message', status: :some_status })
  end

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

  describe '.process_command' do
    context "with 'next', 'continue', or 'onward' command" do
      %w[next continue onward].each do |command|
        it 'processes the next truck for the adventure' do
          result = SmsService.process_command(adventure, command)
          expect(result).to eq({ message: 'some message', status: :some_status })
        end
      end
    end

    context "with 'done' command" do
      it 'completes the adventure' do
        expect(adventure).to receive(:complete)
        result = SmsService.process_command(adventure, 'done')
        expect(result).to eq({ message: 'Congratulations on completing your adventure!', status: :complete })
      end
    end

    context "with 'stop' command" do
      it 'stops the adventure' do
        expect(adventure).to receive(:stop)
        result = SmsService.process_command(adventure, 'stop')
        expect(result).to eq({ message: "Your adventure has been stopped. Reply with 'Next' to continue.",
                               status: :stopped })
      end
    end

    context 'with an unrecognized command' do
      it 'returns an error message' do
        result = SmsService.process_command(adventure, 'foobar')
        expect(result).to eq({ message: "Unrecognized command. Reply with 'Next' to continue your adventure.",
                               status: nil })
      end
    end
  end
end
