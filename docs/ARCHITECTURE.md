# Food Truck Adventure - Architecture Documentation

## System Overview

Food Truck Adventure is an SMS-based interactive application that creates personalized food truck routes for users. The system orchestrates real-time food truck data, background job processing, geocoding, and SMS messaging to deliver a seamless adventure experience.

## Core Components

### 1. Data Layer

#### Models
- **Adventure**: Central aggregate root managing the adventure lifecycle
- **FoodTruck**: Food truck catalog with auto-categorization
- **AdventureFoodTruck**: Join table establishing ordered truck sequences

#### Database
- PostgreSQL with support for array columns (categories)
- Indexes optimized for filtering by status, location, and food preferences
- Geographic coordinates stored as decimal(9,6) for precision

### 2. Background Processing

#### Sidekiq Workers & Jobs
- **SfImportWorker**: Daily scheduled job (midnight) importing SF food truck data
- **AdventureJob**: Delayed job scheduled to run at user's chosen adventure start time
- **AdventureFoodTruckJob**: Async job for organizing food trucks after adventure creation

#### Queue Strategy
- All jobs use `default` queue
- Sidekiq-scheduler manages recurring tasks (CSV import)
- Time-based jobs use Sidekiq's `.set(wait_until:)` for precise scheduling

### 3. External Services

#### Twilio Integration
- **Outbound**: SmsService sends messages for adventure progression
- **Inbound**: Webhook receives user commands via POST to `/sms/receive`
- **Security**: Request signature validation prevents unauthorized webhooks
- **Privacy**: Phone numbers deleted when adventure completes/stops

#### San Francisco Open Data API
- CSV endpoint: `https://data.sfgov.org/api/views/rqzj-sfat/rows.csv`
- Data refresh: Daily import with smart diffing (marks missing records inactive)
- Auto-categorization using keyword matching against predefined categories

#### Geocoding
- Geocoder gem converts zip codes to lat/long
- Haversine formula calculates distances between coordinates
- No external API calls (uses local calculation)

### 4. Business Logic Services

#### FoodTruckOrganizer
**Purpose**: Select and order food trucks for an adventure

**Algorithm**:
1. Filter trucks by category match (PostgreSQL array overlap operator `&&`)
2. Calculate distance from user's zip code to each truck
3. Sort by ascending distance
4. Take top N trucks based on user's requested count
5. Create ordered AdventureFoodTruck records

**Current Limitations**:
- Distance calculated from zip code centroid, not actual starting location
- Sorting optimizes start point distance, not full route efficiency
- Doesn't account for truck operating hours or availability

#### SmsService
**Purpose**: SMS orchestration and command processing

**Commands**:
- Navigation: `next`, `continue`, `onward`, `go`, `move`, `forward`, `advance`, `roll`, `let's go`, etc.
- Termination: `stop` (user-initiated end), `abandon` (different final state)
- Unknown commands return helpful hint message

**Message Flow**:
1. User texts command → Twilio webhook → SmsController
2. Controller validates signature, extracts phone number
3. Finds most recent adventure for that phone number
4. SmsService.process_command executes business logic
5. Response sent back via Twilio API

## State Management

### Adventure Lifecycle States

```
awaiting_start → in_progress → complete
                      ↓
                   stopped
                      ↓
                  abandoned
```

- **awaiting_start**: Default state, scheduled SMS pending
- **in_progress**: Adventure has begun, user navigating between trucks
- **complete**: All trucks visited successfully
- **stopped**: User ended adventure early via 'stop' command
- **abandoned**: User abandoned adventure (separate tracking from stop)

### Truck Progression

Adventures track progression via `current_truck_index`:
- Starts at 0
- Increments with each "next" command
- When index equals number of trucks, adventure completes
- AdventureFoodTruck.order field determines sequence (0-indexed)

## Data Flow Diagrams

### Adventure Creation Flow
```
User Form Submission
    ↓
AdventuresController#create
    ↓
Adventure.create (triggers callbacks)
    ├─→ organize_food_trucks → AdventureFoodTruckJob → FoodTruckOrganizer
    └─→ schedule_initial_sms → AdventureJob (scheduled)
    ↓
Redirect to "Adventure Begins" page
```

### SMS Interaction Flow
```
User sends SMS
    ↓
Twilio Webhook → SmsController#receive
    ↓
Validate Twilio signature
    ↓
Find Adventure by phone_number
    ↓
SmsService.process_command
    ├─→ 'next' → Adventure#process_next_truck
    │              ├─→ advance_to_next_truck!
    │              ├─→ check if on_last_truck?
    │              └─→ complete if finished
    ├─→ 'stop' → Adventure#stop
    └─→ unknown → return hint message
    ↓
SmsService.send_sms (Twilio API)
    ↓
User receives SMS
```

### Food Truck Import Flow
```
Sidekiq-scheduler (daily at midnight)
    ↓
SfImportWorker#perform
    ↓
Fetch CSV from SF Open Data API
    ↓
Validate headers match expected schema
    ↓
For each row:
    ├─→ Categorize food items (keyword matching)
    ├─→ Parse dates and coordinates
    └─→ Update or create FoodTruck record
    ↓
Mark trucks not in CSV as inactive
```

## Security Considerations

1. **CSRF Protection**: Disabled for `/sms/receive` webhook (Twilio can't send CSRF token)
2. **Webhook Validation**: Twilio signature validation prevents replay attacks
3. **PII Handling**: Phone numbers deleted when adventure reaches final state
4. **Credentials**: Encrypted Rails credentials for Twilio API keys
5. **SQL Injection**: All queries use ActiveRecord parameterization

## Performance Characteristics

### Bottlenecks
1. **Geocoding**: Happens synchronously on Adventure create (zip → lat/long)
2. **CSV Import**: Daily import processes ~500-1000 records sequentially
3. **Distance Calculation**: N truck records * haversine calculation on each adventure creation

### Optimization Opportunities
1. Cache geocoded zip codes (same zip appears frequently)
2. Batch import FoodTruck updates
3. Pre-calculate truck distances to common zip codes
4. Index on categories array for faster filtering

### Scalability Considerations
- Sidekiq can scale horizontally for background job processing
- PostgreSQL handles current load; consider partitioning adventures table by date
- Twilio rate limits: current traffic likely under limits; implement exponential backoff if needed
- CSV import could use streaming for larger datasets

## Error Handling

### Import Worker
- Validates CSV headers before processing
- Catches StandardError on CSV fetch (logs, returns empty string)
- Individual row failures don't stop entire import

### SMS Controller
- Returns 401 if Twilio signature invalid
- Handles missing adventures gracefully (sends "no adventure found" message)
- Phone number normalization handles country codes

### Adventure Model
- Validations prevent invalid phone numbers, zip codes
- Geocoding failures prevent record creation
- Status transitions protected by enum

## Testing Strategy

### Test Types
- **Model specs**: Validations, associations, business logic methods
- **Service specs**: FoodTruckOrganizer algorithm, SmsService command processing
- **Job specs**: Ensure jobs enqueue and execute correctly
- **Controller specs**: SMS webhook handling, request validation
- **Worker specs**: CSV import logic, categorization

### Test Data
- FactoryBot factories for models
- VCR cassettes for external API calls (SF Open Data)
- Webmock for Twilio API stubbing
- Database Cleaner ensures test isolation

## Future Architecture Improvements

1. **Event-Driven Architecture**: Publish events (AdventureStarted, TruckVisited) for analytics
2. **CQRS**: Separate read models for adventure history vs. active adventures
3. **Multi-City Support**: Abstract importer interface, city-specific implementations
4. **Route Optimization**: Integrate Google Maps Directions API or OR-Tools
5. **Real-Time Updates**: WebSockets for live adventure tracking on web interface
6. **Caching Layer**: Redis for frequently accessed food truck lists by category
