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

    case body
    when 'next', 'continue', 'onward'
      process_next_truck(adventure)
    when 'done'
      adventure.update(status: :complete)
      SmsService.send_sms(phone_number, 'Congratulations on completing your adventure!')
    else
      SmsService.send_sms(phone_number, "Unrecognized command. Reply with 'Next' to continue your adventure.")
    end
  end

  private

  def process_next_truck(adventure)
    next_truck = adventure.next_truck  # Assume next_truck method gives the next truck or nil if no more trucks
    if next_truck
      message = "Next stop: #{next_truck.name} at #{next_truck.location}. Enjoy!"
      SmsService.send_sms(adventure.phone_number, message)
    else
      message = "Hooray! You've visited all the trucks. Reply 'Done' when you're finished."
      SmsService.send_sms(adventure.phone_number, message)
    end
  end
end

I would also like to implement an emergency stop response that the user can send.Also, the
