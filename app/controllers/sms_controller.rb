class SmsController < ApplicationController
  skip_before_action :verify_authenticity_token # Be sure to secure this endpoint

  def receive
    adventure = Adventure.find_by(phone_number: params[:From])
    # Assume a simple keyword-based system for this example
    case params[:Body].downcase
    when 'complete'
      adventure.update(status: :complete)
      SmsService.send_sms(adventure.phone_number, 'Adventure completed!')
      # ... other cases ...
    end
  end
end
