class SmsController < ApplicationController
  skip_before_action :verify_authenticity_token  # Skip CSRF check for webhook requests

  def receive
    body = params['Body'].strip.downcase
    phone_number = params['From']
    adventure = Adventure.find_by(phone_number:)

    if adventure.nil?
      SmsService.send_sms(phone_number, 'No active adventure found.')
      return
    end

    response = SmsService.process_command(adventure, body)
    SmsService.send_sms(phone_number, response[:message])
  end
end
