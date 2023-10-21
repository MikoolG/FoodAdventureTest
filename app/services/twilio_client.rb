class TwilioClient
  def self.client
    Twilio::REST::Client.new
  end
end
