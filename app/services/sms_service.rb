class SmsService
  def self.send_sms(phone_number, message)
    client = TwilioClient.client
    client.messages.create(
      from: Rails.application.credentials.dig(:twilio, :phone_number),
      to: phone_number,
      body: message
    )
  end

  def self.process_command(adventure, command)
    case command
    when 'next', 'continue', 'onward', 'proceed', 'go', 'move', 'forward', 'advance', 'let’s go', 'let’s move', 'keep going', 'roll', 'roll out'
      adventure.process_next_truck
    when 'stop'
      adventure.stop
      {
        message: '🛑 Your adventure has been stopped. If you feel like doing a new adventure sometime headback to our website!',
        status: :stopped
      }
    when 'abandon'
      adventure.abandon
      {
        message: "😢 It's sad to see you go! Your adventure has been abandoned. 🚚💔",
        status: :abandoned
      }
    else
      {
        message: "🤔 Unrecognized command. Reply with 'Next' to continue your adventure. 🚚",
        status: nil
      }
    end
  end
end
