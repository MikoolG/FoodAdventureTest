# API Integration Guide

## Twilio SMS Integration

### Overview
The application uses Twilio for bidirectional SMS communication with users during their food truck adventures.

### Setup Requirements

1. **Twilio Account**
   - Sign up at https://www.twilio.com
   - Purchase a phone number with SMS capabilities
   - Locate Account SID and Auth Token from console

2. **Rails Credentials Configuration**
   ```bash
   bin/rails credentials:edit
   ```

   Add the following structure:
   ```yaml
   twilio:
     account_sid: YOUR_ACCOUNT_SID
     auth_token: YOUR_AUTH_TOKEN
     phone_number: "+1234567890"  # Your Twilio number with country code
   ```

3. **Webhook Configuration**
   - In Twilio console, navigate to Phone Numbers → Active Numbers
   - Select your number
   - Under "Messaging", configure webhook:
     - **A Message Comes In**: Webhook, HTTP POST
     - **URL**: `https://your-domain.com/sms/receive`
   - Save configuration

### Outbound SMS (Application → User)

**Service**: `SmsService.send_sms(phone_number, message)`

**Usage**:
```ruby
SmsService.send_sms("5551234567", "Your adventure begins!")
```

**Implementation** (app/services/sms_service.rb:4):
```ruby
def self.send_sms(phone_number, message)
  client = TwilioClient.client
  client.messages.create(
    from: Rails.application.credentials.dig(:twilio, :phone_number),
    to: phone_number,
    body: message
  )
end
```

**When Used**:
- Adventure start (AdventureJob)
- Progression messages (after "next" command)
- Completion messages
- Error/help messages

### Inbound SMS (User → Application)

**Webhook Endpoint**: `POST /sms/receive`

**Controller**: `SmsController#receive` (app/controllers/sms_controller.rb:7)

**Expected Parameters** (from Twilio):
- `Body`: The message text sent by user
- `From`: User's phone number (format: +1234567890)
- `To`: Your Twilio number
- Headers include `HTTP_X_TWILIO_SIGNATURE` for validation

**Processing Flow**:
1. Validate Twilio request signature
2. Normalize phone number (strip country code, keep last 10 digits)
3. Find most recent Adventure for that phone number
4. Process command via `SmsService.process_command`
5. Send response SMS

**Security Validation** (app/controllers/sms_controller.rb:31):
```ruby
def validate_twilio_request
  twilio_signature = request.headers['HTTP_X_TWILIO_SIGNATURE']
  validator = Twilio::Security::RequestValidator.new(
    Rails.application.credentials.dig(:twilio, :auth_token)
  )

  return if validator.validate(request.original_url, request.POST, twilio_signature)

  render plain: 'Unauthorized request', status: :unauthorized
end
```

### Supported Commands

| Command | Aliases | Action |
|---------|---------|--------|
| Next | continue, onward, proceed, go, move, forward, advance, roll, "let's go", "keep going" | Advance to next truck |
| Stop | - | End adventure, mark as stopped |
| Abandon | - | Mark adventure as abandoned |
| Unknown | - | Return help message |

**Command Processing** (app/services/sms_service.rb:13):
```ruby
def self.process_command(adventure, command)
  case command
  when 'next', 'continue', 'onward', 'proceed', 'go', 'move', 'forward', 'advance', 'let\'s go', 'let\'s move', 'keep going', 'roll', 'roll out'
    adventure.process_next_truck
  when 'stop'
    adventure.stop
    { message: '🛑 Your adventure has been stopped...', status: :stopped }
  when 'abandon'
    adventure.abandon
    { message: '😢 It\'s sad to see you go!...', status: :abandoned }
  else
    { message: '🤔 Unrecognized command. Reply with \'Next\' to continue...', status: nil }
  end
end
```

### Testing Twilio Integration

**Test Mode**:
- Use Twilio's test credentials for development
- Test phone numbers: https://www.twilio.com/docs/iam/test-credentials

**Local Webhook Testing**:
1. Use ngrok to expose local server:
   ```bash
   ngrok http 3000
   ```
2. Update Twilio webhook URL to ngrok URL: `https://your-ngrok-url.ngrok.io/sms/receive`
3. Send test SMS to your Twilio number
4. Check Rails logs for webhook POST

**RSpec Tests**:
- Use VCR to record/replay Twilio API responses
- Webmock stubs external HTTP calls
- See `spec/services/sms_service_spec.rb` and `spec/controllers/sms_controller_spec.rb`

### Rate Limits & Error Handling

**Twilio Limits**:
- Default: 1 message/second per phone number
- Queue: Up to 4 hours ahead
- See: https://www.twilio.com/docs/usage/tutorials/how-to-use-your-free-trial-account

**Error Handling**:
- Twilio gem raises `Twilio::REST::RestError` on failures
- Current implementation doesn't retry (consider adding exponential backoff)
- Failed messages should be logged for monitoring

**Recommended Improvements**:
```ruby
def self.send_sms(phone_number, message)
  client = TwilioClient.client
  client.messages.create(
    from: Rails.application.credentials.dig(:twilio, :phone_number),
    to: phone_number,
    body: message
  )
rescue Twilio::REST::RestError => e
  Rails.logger.error("Twilio SMS failed: #{e.message}")
  # Consider: Retry logic, dead letter queue, user notification
  raise
end
```

---

## San Francisco Open Data API

### Overview
Daily import of food truck permit data from SF Open Data portal.

### API Endpoint
**URL**: `https://data.sfgov.org/api/views/rqzj-sfat/rows.csv?accessType=DOWNLOAD`

**Format**: CSV

**Documentation**: https://data.sfgov.org/Economy-and-Community/Mobile-Food-Facility-Permit/rqzj-sfat

### Data Schema

**Expected Headers** (SfImportWorker:11):
```
locationid, Applicant, FacilityType, cnn, LocationDescription, Address,
blocklot, block, lot, permit, Status, FoodItems, X, Y, Latitude, Longitude,
Schedule, dayshours, NOISent, Approved, Received, PriorPermit, ExpirationDate,
Location, Fire Prevention Districts, Police Districts, Supervisor Districts,
Zip Codes, Neighborhoods (old)
```

### Import Process

**Schedule**: Daily at midnight (config/sidekiq_schedule.yml:2)

**Worker**: `SfImportWorker` (app/workers/sf_import_worker.rb)

**Algorithm**:
1. Fetch CSV via HTTP GET
2. Validate headers match expected schema (prevents processing corrupted data)
3. Parse each row:
   - Extract applicant name, address, food items, coordinates, dates
   - Auto-categorize based on food_items keywords
   - Set city to "San Francisco", state to "CA"
4. Update or create FoodTruck record (matched by applicant + address)
5. Mark trucks not in CSV as `active: false` (soft delete)

**Categorization Logic** (app/workers/sf_import_worker.rb:67):
```ruby
def categorize_food(food_items)
  return [] unless food_items

  categories = []
  FoodTruck::CATEGORIES.each do |category, keywords|
    categories << category if keywords.any? { |keyword| food_items.downcase.include?(keyword.downcase) }
  end

  categories
end
```

**Error Handling**:
- CSV fetch wrapped in rescue (logs error, returns empty string)
- Header validation prevents processing if schema changes
- Individual row failures don't halt import

### Testing Import

**Manual Trigger**:
```ruby
# Rails console
SfImportWorker.new.perform
```

**RSpec**:
```ruby
# spec/workers/sf_import_worker_spec.rb
# Uses VCR to cache CSV responses
```

### Rate Limits
- No published rate limits for SF Open Data
- Current once-daily schedule well within limits
- Consider adding retry with backoff if fetch fails

### Data Quality Notes
- Some trucks have missing coordinates (will fail FoodTruck validation)
- Expiration dates can be in various formats (parsed as: `%m/%d/%Y %I:%M:%S %p`)
- Food items free-text field requires robust categorization
- Active/inactive status inferred from CSV presence (trucks may be temporarily removed)

### Future: Multi-City Support

To support additional cities, create new importers following this pattern:

```ruby
class ChicagoImportWorker
  include Sidekiq::Worker

  CSV_URL = 'https://data.cityofchicago.org/...'

  def perform
    # City-specific import logic
  end

  private

  def set_location_attributes(row)
    {
      city: 'Chicago',
      state: 'IL',
      # Map Chicago CSV columns to FoodTruck attributes
    }
  end
end
```

Schedule in `config/sidekiq_schedule.yml`:
```yaml
chicago_import_worker:
  cron: "0 1 * * *"  # 1 AM daily
  class: ChicagoImportWorker
```

---

## Google Maps API (Future Enhancement)

### Current State
**Not currently integrated**. The codebase references Google Maps in:
- JavaScript controllers (app/javascript/controllers/google_maps_controller.js)
- Adventure views may expect maps functionality

### Recommended Integration

**Use Case**: Optimize food truck route beyond simple distance sorting

**API**: Google Maps Directions API
- Calculates actual driving routes between multiple waypoints
- Returns optimized order for visiting locations
- Provides turn-by-turn directions

**Setup**:
1. Enable Directions API in Google Cloud Console
2. Create API key with restrictions (HTTP referrers for web, IP for server)
3. Add to Rails credentials:
   ```yaml
   google_maps:
     api_key: YOUR_API_KEY
   ```

**Implementation Example**:
```ruby
# app/services/route_optimizer.rb
class RouteOptimizer
  def initialize(origin, waypoints)
    @origin = origin  # [lat, lng]
    @waypoints = waypoints  # [[lat, lng], ...]
  end

  def optimize
    # Call Google Directions API with optimize:true
    # Return ordered waypoints
  end
end
```

**Replace FoodTruckOrganizer logic**:
```ruby
# Instead of simple distance sorting
sorted_trucks = trucks.sort_by { |truck| distance_from_adventure(truck, @adventure) }

# Use route optimization
optimizer = RouteOptimizer.new(
  [@adventure.latitude, @adventure.longitude],
  trucks.map { |t| [t.latitude, t.longitude] }
)
optimized_order = optimizer.optimize
```

**Cost Considerations**:
- Directions API: $5 per 1000 requests (first $200/month free)
- Current adventure volume likely within free tier
- Cache routes for same truck combinations to reduce API calls
