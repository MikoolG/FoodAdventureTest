# frozen_string_literal: true

class SmsController < ApplicationController
  skip_before_action :verify_authenticity_token  # Skip CSRF check for webhook requests

  def receive
    body = params['Body'].strip.downcase
    phone_number = params['From']
    adventure = Adventure.find_by(phone_number:)

    if adventure.nil?
      SmsService.send_sms(
        phone_number,
        "🕵️ Oops! It seems like there's no active adventure linked to this number. Craving some culinary quests? Head over to [FoodTruckAdventure.com](https://foodtruckadventure.com) to cook up a new Food Truck Adventure! 🚚🌮"
      )
      return
    end

    response = SmsService.process_command(adventure, body)
    SmsService.send_sms(phone_number, response[:message])
  end
end
