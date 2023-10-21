class AdventureJob < ApplicationJob
  queue_as :default

  def perform(adventure_id)
    adventure = Adventure.find(adventure_id)
    SmsService.send_sms(adventure.phone_number, 'Your adventure has started!')
  end
end
