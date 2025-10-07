# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Food Truck Adventure is a Rails 7 application that creates personalized food truck adventures for users in San Francisco. Users input their food preferences, desired number of trucks, and adventure timing. The app finds matching food trucks, calculates an optimal route based on distance, and guides users via SMS messages to each location.

**Key Technologies:**
- Ruby 3.2.0, Rails 7
- PostgreSQL database
- Sidekiq for background job processing (scheduled jobs via sidekiq-scheduler)
- Twilio API for SMS messaging
- Geocoder gem with haversine formula for distance calculations
- Tailwind CSS for UI styling (colors: Blue #00CAE3, Pink #FF7F96, Gray #CDDCE8)
- Stimulus.js for JavaScript interactions

## Development Commands

**Setup (first time only):**
```bash
bundle install
npm install
bundle exec rails db:create db:migrate
```

**Running the application:**
```bash
./bin/start   # All-in-one startup: Rails, Sidekiq, auto-imports food trucks (recommended)
./bin/stop    # Stop all services cleanly
./bin/restart # Restart all services
```

**What `./bin/start` does:**
- Builds Tailwind CSS assets
- Checks & starts PostgreSQL and Redis
- Creates database if needed
- **Imports 484 SF food trucks if database is empty**
- Starts Rails server (daemon mode, port 3000)
- Starts Sidekiq worker (daemon mode)
- All services run in background

**Alternative manual startup:**
```bash
bundle exec rails server -p 3000  # Terminal 1: Rails web server
bundle exec sidekiq               # Terminal 2: Background jobs
```

For detailed startup documentation, see `docs/STARTUP.md`

**Running tests:**
```bash
bundle exec rspec                    # Run all tests
bundle exec rspec spec/models        # Run model tests
bundle exec rspec spec/path/to/file_spec.rb  # Run single test file
```

**Linting:**
```bash
bundle exec rubocop                  # Run rubocop linter
bundle exec rubocop -a              # Auto-fix violations
```

## Architecture & Data Flow

### Core Models & Relationships

**Adventure** (central model)
- Represents a user's food truck adventure session
- Has many `FoodTruck` records through `AdventureFoodTruck` join table
- Tracks adventure state via enum: `awaiting_start`, `in_progress`, `complete`, `stopped`, `abandoned`
- Uses geocoder gem to convert zip_code to lat/long coordinates
- Phone number is deleted when adventure reaches final status (privacy feature)
- `current_truck_index` tracks progression through the adventure

**FoodTruck**
- Contains food truck data imported from SF Open Data CSV
- Categories are auto-assigned based on keywords in food_items field (see CATEGORIES constant in app/models/food_truck.rb:12)
- `active` flag indicates if truck is still in CSV (updated by import worker)

**AdventureFoodTruck** (join table)
- Links Adventures to FoodTrucks with an `order` field for route sequencing
- Order starts from 0

### Application Flow

1. **Adventure Creation** (AdventuresController#create)
   - User submits form with preferences (phone, food_preference, number_of_trucks, adventure_day, adventure_start_time, zip_code)
   - Adventure record created with status `awaiting_start`
   - Two callbacks fire on Adventure creation:
     - `organize_food_trucks`: Enqueues `AdventureFoodTruckJob`
     - `schedule_initial_sms`: Schedules `AdventureJob` to run at adventure_start_time

2. **Food Truck Selection** (AdventureFoodTruckJob → FoodTruckOrganizer)
   - Filters FoodTruck records where categories array contains the user's food_preference
   - Sorts by distance from adventure's zip code using haversine formula (Geocoder::Calculations.distance_between)
   - Takes top N trucks (user's number_of_trucks)
   - Creates AdventureFoodTruck records with sequential order values (0, 1, 2...)

3. **Adventure Begins** (AdventureJob runs at scheduled time)
   - Sends initial SMS with first truck location
   - User texts commands back to interact with adventure

4. **SMS Interaction** (SmsController#receive → SmsService)
   - Twilio webhook posts to `/sms/receive` when user texts
   - Controller validates Twilio signature for security
   - Extracts phone number and matches to most recent Adventure
   - SmsService.process_command handles commands:
     - `next/continue/onward/go/move/forward/advance/roll` etc. → advances to next truck
     - `stop` → ends adventure with stopped status
     - `abandon` → marks adventure as abandoned
   - Adventure#process_next_truck increments current_truck_index and returns next location
   - When last truck visited, adventure status changes to `complete`

### Key Services & Background Jobs

**FoodTruckOrganizer** (app/services/food_truck_organizer.rb)
- Core algorithm for selecting and ordering food trucks
- Current implementation uses simple distance-based sorting (haversine formula via geocoder)
- Known limitation: doesn't optimize for actual route efficiency between trucks

**SmsService** (app/services/sms_service.rb)
- Handles sending SMS via Twilio
- Processes incoming commands with flexible keyword matching

**TwilioClient** (app/services/twilio_client.rb)
- Wrapper for Twilio client initialization

**SfImportWorker** (app/workers/sf_import_worker.rb)
- Scheduled daily via sidekiq-scheduler (config/sidekiq_schedule.yml:2)
- Fetches CSV from SF Open Data API
- Creates/updates FoodTruck records
- Marks trucks not in CSV as `active: false`
- Auto-categorizes food items using keyword matching (FoodTruck::CATEGORIES)

**AdventureJob** (app/jobs/adventure_job.rb)
- Sends initial SMS when adventure starts (scheduled via Sidekiq)

**AdventureFoodTruckJob** (app/jobs/adventure_food_truck_job.rb)
- Runs FoodTruckOrganizer to populate adventure's food trucks

## Configuration & Credentials

**Required Credentials** (stored in encrypted credentials):
```ruby
Rails.application.credentials.dig(:twilio, :phone_number)
Rails.application.credentials.dig(:twilio, :auth_token)
Rails.application.credentials.dig(:twilio, :account_sid)  # Used in TwilioClient
```

Edit credentials: `bin/rails credentials:edit`

**Twilio Webhook Setup:**
- Configure Twilio phone number webhook to POST to: `https://your-domain.com/sms/receive`
- Webhook includes request signature validation (SmsController validates via Twilio::Security::RequestValidator)

## Database Schema Notes

- Adventures table has indexes on: city, food_preference, state, status
- FoodTrucks table has indexes on: active, facility_type, food_items, status
- Categories in food_trucks are stored as PostgreSQL text array (`array: true`)

## Known Limitations & Improvement Areas

1. **Routing Algorithm**: Current implementation uses simple distance sorting from user's zip code. Doesn't optimize the route between trucks (traveling salesman problem). Consider implementing proper route optimization.

2. **Geographic Coverage**: Only supports San Francisco (SF Open Data CSV source). Need additional importers for other cities.

3. **Adventure Expiration**: No automatic cleanup of stale adventures (suggestion: expire adventures not updated in 24 hours).

4. **Post-Adventure Features**: No feedback/rating system after completion.

5. **Truck Operating Hours**: Food truck schedule/days_hours fields exist but aren't used in filtering logic. Should validate trucks are open during adventure time window.

## Testing

- Uses RSpec with FactoryBot for test data
- VCR for mocking HTTP requests to external APIs
- Database Cleaner for test isolation (supports both ActiveRecord and Redis)
- Webmock for stubbing HTTP requests
- Test coverage includes: models, services, jobs, workers, controllers
