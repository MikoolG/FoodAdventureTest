# Future Improvements & Roadmap

This document outlines potential enhancements to the Food Truck Adventure application, categorized by impact and effort.

## High Priority (High Impact, Medium-High Effort)

### 1. Route Optimization Algorithm

**Current State**:
- Trucks sorted by straight-line distance from user's zip code
- Doesn't optimize the actual route between multiple trucks
- Ignores real road networks and traffic

**Proposed Solution**:
- Integrate Google Maps Directions API with waypoint optimization
- Implement traveling salesman problem (TSP) solver for optimal route
- Consider libraries: OR-Tools, Concorde TSP solver

**Implementation**:
```ruby
class RouteOptimizer
  def initialize(origin, destinations)
    @origin = origin  # User's starting location
    @destinations = destinations  # Array of truck locations
  end

  def optimize
    # Option 1: Google Maps API
    response = google_directions_api_call(waypoints: @destinations, optimize: true)
    parse_optimized_order(response)

    # Option 2: Local TSP solver (for cost savings)
    distance_matrix = calculate_distance_matrix
    solve_tsp(distance_matrix)
  end
end
```

**Benefits**:
- Better user experience (less travel time)
- More realistic routes following roads
- Could suggest departure times to hit trucks when open

**Estimated Effort**: 2-3 weeks

---

### 2. Multi-City Expansion

**Current State**:
- Only supports San Francisco via `SfImportWorker`
- City and state hardcoded to "San Francisco, CA"

**Proposed Solution**:
- Abstract import logic into base class
- Create city-specific importers
- Add city selection to adventure creation form
- Scope truck queries by city

**Implementation**:
```ruby
# app/workers/base_import_worker.rb
class BaseImportWorker
  include Sidekiq::Worker

  def perform
    return unless valid_headers?

    parsed_csv.each { |row| update_or_create_food_truck(row) }
    mark_missing_records_as_inactive
  end

  private

  def csv_url
    raise NotImplementedError
  end

  def city_name
    raise NotImplementedError
  end

  def state_abbreviation
    raise NotImplementedError
  end
end

# app/workers/chicago_import_worker.rb
class ChicagoImportWorker < BaseImportWorker
  def csv_url
    'https://data.cityofchicago.org/...'
  end

  def city_name
    'Chicago'
  end

  def state_abbreviation
    'IL'
  end
end
```

**Target Cities**:
- Los Angeles (large food truck scene)
- Portland (food cart pods)
- Austin (thriving food truck culture)
- New York City (street food vendors)

**Estimated Effort**: 3-4 weeks (includes data source research)

---

### 3. Operating Hours Validation

**Current State**:
- `schedule` and `days_hours` fields exist but aren't used
- Users could be routed to closed trucks
- No time-of-day filtering

**Proposed Solution**:
- Parse schedule strings into structured time ranges
- Filter trucks by operating hours during adventure time window
- Show operating hours in truck details
- Warn users if adventure timing means few trucks available

**Implementation**:
```ruby
# app/models/food_truck.rb
def open_at?(datetime)
  return false unless schedule.present?

  # Parse schedule format (varies by data source)
  # Example: "Mo-Fr:10AM-2PM"
  parsed_schedule = ScheduleParser.parse(schedule)
  parsed_schedule.includes?(datetime)
end

# app/services/food_truck_organizer.rb
def organize
  trucks = FoodTruck.where('categories && ARRAY[?]::text[]', @adventure.food_preference)

  # Filter by operating hours
  adventure_time = @adventure.combined_start_time
  open_trucks = trucks.select { |truck| truck.open_at?(adventure_time) }

  sorted_trucks = open_trucks.sort_by { |truck| distance_from_adventure(truck, @adventure) }
  # ...
end
```

**Challenges**:
- Schedule data format inconsistent across sources
- Some trucks list "See website" instead of hours
- Need robust parsing or manual curation

**Estimated Effort**: 2 weeks

---

## Medium Priority (Medium Impact, Low-Medium Effort)

### 4. Adventure Expiration & Cleanup

**Current State**:
- Old adventures persist indefinitely
- Phone numbers only deleted on completion/stop
- No automatic cleanup of stale data

**Proposed Solution**:
- Background job to mark adventures as `abandoned` if inactive 24+ hours
- Cleanup job to archive old completed adventures
- Dashboard showing cleanup stats

**Implementation**:
```ruby
# app/workers/adventure_cleanup_worker.rb
class AdventureCleanupWorker
  include Sidekiq::Worker

  def perform
    # Mark stale adventures as abandoned
    stale_cutoff = 24.hours.ago
    Adventure.where(status: [:awaiting_start, :in_progress])
             .where('updated_at < ?', stale_cutoff)
             .update_all(status: :abandoned)

    # Archive old completed adventures (optional)
    archive_cutoff = 90.days.ago
    Adventure.where(status: [:complete, :stopped, :abandoned])
             .where('created_at < ?', archive_cutoff)
             .find_each do |adventure|
               ArchiveAdventure.call(adventure)
               adventure.destroy
             end
  end
end

# config/sidekiq_schedule.yml
adventure_cleanup_worker:
  cron: "0 3 * * *"  # 3 AM daily
  class: AdventureCleanupWorker
```

**Estimated Effort**: 3-5 days

---

### 5. Post-Adventure Feedback & Ratings

**Current State**:
- No feedback loop after adventure completes
- Can't track user satisfaction
- No truck ratings

**Proposed Solution**:
- Send final SMS with feedback link
- Simple web form: rate adventure 1-5 stars, optional comment
- Rate individual trucks visited
- Analytics dashboard for operators

**Implementation**:
```ruby
# New models
class AdventureFeedback < ApplicationRecord
  belongs_to :adventure
  validates :rating, inclusion: { in: 1..5 }
end

class TruckRating < ApplicationRecord
  belongs_to :food_truck
  belongs_to :adventure
  validates :rating, inclusion: { in: 1..5 }
end

# Update completion message
def complete_message
  feedback_url = Rails.application.routes.url_helpers.feedback_url(token: generate_feedback_token)
  {
    message: "🎉 Adventure complete! Rate your experience: #{feedback_url}",
    status: :complete
  }
end
```

**Estimated Effort**: 1 week

---

### 6. User Accounts & Adventure History

**Current State**:
- No user accounts
- Phone number only identifier
- Can't view past adventures

**Proposed Solution**:
- Optional user registration (email + password)
- Link adventures to user account
- Dashboard showing past adventures
- Favorite food trucks
- Repeat previous adventure

**Implementation**:
- Add Devise gem for authentication
- `User` model with `has_many :adventures`
- Optional: social login (Google, Facebook)

**Estimated Effort**: 1-2 weeks

---

## Low Priority (Nice-to-Have, Various Effort)

### 7. Real-Time Adventure Tracking

**Current State**:
- SMS-only interaction
- No web-based progress tracking

**Proposed Solution**:
- Live web dashboard showing adventure progress
- Map with truck locations and route
- WebSockets (Action Cable) for real-time updates
- Share adventure link with friends to track

**Estimated Effort**: 1-2 weeks

---

### 8. Social Features

- Share completed adventures on social media
- Leaderboards (most adventures, most trucks visited)
- Group adventures (multiple people, same route)
- Photo uploads at each truck
- Instagram integration

**Estimated Effort**: 2-4 weeks

---

### 9. Advanced Preferences

**Current State**:
- Single food preference
- Fixed number of trucks

**Enhancements**:
- Multiple food preferences ("Mexican OR Thai")
- Exclude specific cuisines
- Dietary restrictions (vegetarian, vegan, gluten-free, halal)
- Price range filter
- Minimum truck rating (if ratings implemented)
- Maximum distance willing to travel

**Estimated Effort**: 1 week

---

### 10. Truck Discovery Features

- Trending trucks (most visited this week)
- New truck alerts
- Seasonal/event-based trucks
- Food truck festivals
- Curated adventure themes ("Dessert Crawl", "Taco Tuesday Tour")

**Estimated Effort**: 1-2 weeks per feature

---

### 11. Admin Dashboard

**Current State**:
- No admin interface
- Database queries via Rails console

**Proposed Solution**:
- Admin panel (ActiveAdmin or custom)
- Manage food trucks (edit details, mark inactive)
- View adventure analytics
- User management
- Manual import trigger
- View Sidekiq job status

**Estimated Effort**: 1-2 weeks

---

### 12. Enhanced SMS Interactions

**Current Commands**: next, stop, abandon

**New Commands**:
- `info` - Get current truck details (hours, specialties)
- `skip` - Skip current truck, move to next
- `pause` - Pause adventure, resume later
- `directions` - Get turn-by-turn directions
- `call` - Get truck's phone number
- `menu` - Get menu link if available

**Implementation**:
```ruby
def self.process_command(adventure, command)
  case command
  when 'info', 'details'
    truck_info_message(adventure.next_truck)
  when 'skip'
    adventure.skip_current_truck!
    adventure.process_next_truck
  when 'pause'
    adventure.pause
    { message: '⏸️ Adventure paused. Text "resume" when ready!', status: nil }
  when 'resume'
    adventure.resume
    adventure.next_truck_message
  # ... existing commands
  end
end
```

**Estimated Effort**: 3-5 days

---

### 13. Internationalization

- Multi-language support (Spanish, Chinese, etc.)
- Localized SMS messages
- International phone number support
- Currency localization (if pricing added)

**Estimated Effort**: 1-2 weeks

---

### 14. Analytics & Insights

**User-Facing**:
- "You've visited X trucks across Y adventures"
- "Most popular cuisine: Mexican"
- "Total miles traveled on adventures"

**Business-Facing**:
- Daily/weekly adventure metrics
- Conversion funnel (form views → completed adventures)
- Most popular food categories
- Geographic heatmaps of adventures
- Peak usage times
- SMS response time tracking

**Estimated Effort**: 1-2 weeks

---

## Technical Debt & Infrastructure

### Performance Optimizations

1. **Database Query Optimization**:
   - Add composite indexes for common queries
   - Implement counter caches (truck rating counts)
   - Partition adventures table by date

2. **Caching**:
   - Cache geocoded zip codes (Redis)
   - Cache food truck lists by category
   - Fragment caching for truck details
   - HTTP caching headers

3. **Background Job Improvements**:
   - Implement retry with exponential backoff
   - Dead letter queue for permanently failed jobs
   - Job performance monitoring

### Code Quality

1. **Test Coverage**:
   - Current coverage unknown (add SimpleCov)
   - Add integration tests (system specs)
   - Test SMS end-to-end flow
   - Load testing (simulate multiple concurrent adventures)

2. **Code Documentation**:
   - YARD documentation for services
   - API documentation (if public API added)
   - Inline comments for complex algorithms

3. **Security Audit**:
   - Brakeman scan for vulnerabilities
   - Bundle audit for gem vulnerabilities
   - Penetration testing
   - Rate limiting on endpoints

### DevOps

1. **CI/CD Pipeline**:
   - GitHub Actions or CircleCI
   - Automated test runs on PRs
   - Automatic deploy to staging
   - Manual promotion to production

2. **Monitoring Enhancements**:
   - Set up Sentry or Rollbar
   - New Relic or DataDog APM
   - Custom dashboards (Grafana)
   - Alerting rules (PagerDuty)

3. **Infrastructure as Code**:
   - Terraform for infrastructure
   - Docker for local development consistency
   - Kubernetes for production (if scaling needed)

---

## Prioritization Framework

When deciding what to build next, consider:

1. **User Impact**: How many users benefit? How much?
2. **Business Value**: Revenue potential, user retention, competitive advantage
3. **Technical Feasibility**: Complexity, dependencies, risks
4. **Resource Availability**: Team size, skill sets, time
5. **Strategic Alignment**: Long-term vision, market positioning

**Recommended Next Steps**:
1. Route Optimization (biggest user experience improvement)
2. Operating Hours Validation (prevents bad experiences)
3. Post-Adventure Feedback (enables data-driven decisions)
4. Multi-City Expansion (increases market size)
