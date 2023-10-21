class SmsService
  def self.send_sms(phone_number, message)
    client = TwilioClient.client
    client.messages.create(
      from: Rails.application.credentials.dig(:twilio, :phone_number),
      to: phone_number,
      body: message
    )
  end
end
