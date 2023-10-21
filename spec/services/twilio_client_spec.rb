require 'rails_helper'

RSpec.describe TwilioClient do
  describe '.client' do
    it 'returns a Twilio::REST::Client instance' do
      expect(Twilio::REST::Client).to receive(:new).with(
        Rails.application.credentials.dig(:twilio, :account_sid),
        Rails.application.credentials.dig(:twilio, :auth_token)
      )
      TwilioClient.client
    end
  end
end
