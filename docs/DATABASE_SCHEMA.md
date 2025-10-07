# Database Schema Documentation

## Overview

Food Truck Adventure uses PostgreSQL with the following key features:
- Array columns for categories (PostgreSQL-specific)
- Decimal precision for geographic coordinates
- Enum-based status tracking (via Rails enum)
- Foreign key constraints for referential integrity

## Entity Relationship Diagram

```
┌─────────────┐          ┌──────────────────────┐          ┌─────────────┐
│  Adventure  │          │ AdventureFoodTruck   │          │ FoodTruck   │
├─────────────┤          ├──────────────────────┤          ├─────────────┤
│ id          │◄────────┤ adventure_id (FK)    │          │ id          │
│ phone_number│          │ food_truck_id (FK)   ├─────────►│ applicant   │
│ food_prefe..│          │ order                │          │ address     │
│ city        │          │ created_at           │          │ categories[]│
│ state       │          │ updated_at           │          │ latitude    │
│ zip_code    │          └──────────────────────┘          │ longitude   │
│ latitude    │                                             │ active      │
│ longitude   │                                             │ ...         │
│ number_of...│                                             └─────────────┘
│ adventure...│
│ adventure...│
│ status      │
│ current_t...│
│ created_at  │
│ updated_at  │
└─────────────┘
```

---

## Table: `adventures`

**Purpose**: Stores user-created food truck adventures with routing preferences and state tracking.

### Columns

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Auto-incrementing primary key |
| `phone_number` | string | nullable | User's phone (10 digits). Deleted on completion for privacy |
| `food_preference` | string | NOT NULL | Food category selected by user |
| `city` | string | NOT NULL | Adventure city (currently always "San Francisco") |
| `state` | string | nullable | State abbreviation (currently "CA") |
| `zip_code` | string | NOT NULL, format: /\A\d{5}(-\d{4})?\z/ | User's starting location zip code |
| `latitude` | decimal(9,6) | nullable | Geocoded latitude from zip_code |
| `longitude` | decimal(9,6) | nullable | Geocoded longitude from zip_code |
| `number_of_trucks` | integer | NOT NULL, >= 1 | How many trucks user wants to visit |
| `adventure_day` | date | NOT NULL | Date of the adventure |
| `adventure_start_time` | time | NOT NULL | Time adventure should begin |
| `status` | integer | NOT NULL, default: 0 | Enum: 0=awaiting_start, 1=in_progress, 2=complete, 3=stopped, 4=abandoned |
| `current_truck_index` | integer | NOT NULL, default: 0 | Tracks progression through trucks (0-based) |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Record update timestamp |

### Indexes

```sql
CREATE INDEX index_adventures_on_city ON adventures (city);
CREATE INDEX index_adventures_on_food_preference ON adventures (food_preference);
CREATE INDEX index_adventures_on_state ON adventures (state);
CREATE INDEX index_adventures_on_status ON adventures (status);
```

### Validations (Model-Level)

```ruby
validates :phone_number, presence: true, format: { with: /\A\d{10}\z/ }
validates :food_preference, presence: true
validates :city, presence: true
validates :zip_code, presence: true, format: { with: /\A\d{5}(-\d{4})?\z/ }
validates :number_of_trucks, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
validates :adventure_day, presence: true
validates :adventure_start_time, presence: true
```

### Status Enum Values

| Integer | Symbol | Description |
|---------|--------|-------------|
| 0 | `:awaiting_start` | Adventure created, scheduled SMS pending |
| 1 | `:in_progress` | Adventure started, user navigating |
| 2 | `:complete` | All trucks visited successfully |
| 3 | `:stopped` | User ended adventure early via "stop" command |
| 4 | `:abandoned` | Adventure abandoned (different from stopped) |

### Callbacks

```ruby
after_validation :geocode  # Geocoder gem converts zip_code to lat/lng
before_update :clear_phone_number, if: :status_changed_to_final?
after_create :organize_food_trucks, :schedule_initial_sms
```

---

## Table: `food_trucks`

**Purpose**: Catalog of food trucks imported from San Francisco Open Data.

### Columns

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Auto-incrementing primary key |
| `applicant` | string | NOT NULL, max 255 | Food truck business name |
| `facility_type` | string | nullable | Type: "Truck", "Push Cart", etc. |
| `location_description` | text | nullable | Human-readable location (e.g., "Corner of Market & 5th") |
| `address` | string | NOT NULL, max 255 | Street address |
| `status` | string | NOT NULL | Permit status: "APPROVED", "REQUESTED", etc. |
| `categories` | text[] | default: [], PostgreSQL array | Auto-categorized food types |
| `food_items` | text | nullable | Free-text list of food items sold |
| `latitude` | decimal(9,6) | NOT NULL | Geographic latitude |
| `longitude` | decimal(9,6) | NOT NULL | Geographic longitude |
| `schedule` | string | nullable | Operating schedule (format varies) |
| `days_hours` | string | nullable | Days and hours of operation |
| `city` | string | nullable | City (always "San Francisco" for current data) |
| `state` | string | nullable | State abbreviation (always "CA" for current data) |
| `active` | boolean | default: true | False if truck no longer in CSV import |
| `expiration_date` | date | nullable | Permit expiration date |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Record update timestamp |

### Indexes

```sql
CREATE INDEX index_food_trucks_on_active ON food_trucks (active);
CREATE INDEX index_food_trucks_on_facility_type ON food_trucks (facility_type);
CREATE INDEX index_food_trucks_on_food_items ON food_trucks (food_items);
CREATE INDEX index_food_trucks_on_status ON food_trucks (status);
```

### Categories (PostgreSQL Array)

The `categories` column stores an array of strings. Categories are auto-assigned during CSV import based on keyword matching in `food_items`.

**Example**:
```ruby
food_truck.categories
# => ["Mexican Food", "Tacos", "Burritos"]
```

**Category Constants** (defined in model):
```ruby
FoodTruck::CATEGORIES = {
  'Breakfast Items' => %w[bacon eggs ham breakfast],
  'Hot Dogs' => %w[hot dogs sausage],
  'Beverages' => %w[beverages soda water juice drinks coffee],
  'Pastries and Desserts' => %w[pastries dessert ice cream donuts],
  'Vegan' => %w[vegan],
  'Latin American Food' => %w[tacos burritos quesadillas],
  'Asian Food' => %w[noodles filipino sushi asian bao],
  'Seafood' => %w[lobster crab ceviche fish],
  'Sandwiches, Melts, and Burgers' => %w[sandwiches melts burgers],
  # ... see app/models/food_truck.rb:12 for full list
}
```

### Scopes

```ruby
FoodTruck.active  # WHERE active = true
```

---

## Table: `adventure_food_trucks`

**Purpose**: Join table linking adventures to food trucks with route ordering.

### Columns

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PK, NOT NULL | Auto-incrementing primary key |
| `adventure_id` | bigint | FK, NOT NULL | References adventures.id |
| `food_truck_id` | bigint | FK, NOT NULL | References food_trucks.id |
| `order` | integer | NOT NULL, default: 0 | Sequence number (0-indexed) for route order |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Record update timestamp |

### Indexes

```sql
CREATE INDEX index_adventure_food_trucks_on_adventure_id ON adventure_food_trucks (adventure_id);
CREATE INDEX index_adventure_food_trucks_on_food_truck_id ON adventure_food_trucks (food_truck_id);
```

### Foreign Keys

```sql
ALTER TABLE adventure_food_trucks
  ADD CONSTRAINT fk_rails_... FOREIGN KEY (adventure_id) REFERENCES adventures(id);

ALTER TABLE adventure_food_trucks
  ADD CONSTRAINT fk_rails_... FOREIGN KEY (food_truck_id) REFERENCES food_trucks(id);
```

### Validations (Model-Level)

```ruby
validates :order, uniqueness: { scope: :adventure_id }
validates :order, numericality: { only_integer: true }
validates :adventure, :food_truck, presence: true
```

### Scopes

```ruby
AdventureFoodTruck.ordered  # ORDER BY order ASC
```

### Usage

The `order` field determines the sequence of trucks in the adventure:

```ruby
adventure.adventure_food_trucks.ordered
# => [
#   #<AdventureFoodTruck order: 0, food_truck: "Taco Truck">,
#   #<AdventureFoodTruck order: 1, food_truck: "Pizza Truck">,
#   #<AdventureFoodTruck order: 2, food_truck: "Ice Cream Truck">
# ]
```

When user texts "next", `current_truck_index` increments to find the next truck by order.

---

## Migrations

### Create Adventures
**File**: `db/migrate/20231019193840_create_adventures.rb`

```ruby
create_table :adventures do |t|
  t.string :phone_number
  t.string :food_preference
  t.string :city
  t.string :state
  t.string :zip_code
  t.decimal :latitude, precision: 9, scale: 6
  t.decimal :longitude, precision: 9, scale: 6
  t.integer :number_of_trucks
  t.date :adventure_day
  t.time :adventure_start_time
  t.integer :status, default: 0
  t.integer :current_truck_index, default: 0
  t.timestamps
end

add_index :adventures, :city
add_index :adventures, :food_preference
add_index :adventures, :state
add_index :adventures, :status
```

### Create Food Trucks
**File**: `db/migrate/20231019194409_create_food_trucks.rb`

```ruby
create_table :food_trucks do |t|
  t.string :applicant
  t.string :facility_type
  t.text :location_description
  t.string :address
  t.string :status
  t.text :categories, array: true, default: []
  t.text :food_items
  t.decimal :latitude, precision: 9, scale: 6
  t.decimal :longitude, precision: 9, scale: 6
  t.string :schedule
  t.string :days_hours
  t.string :city
  t.string :state
  t.boolean :active, default: true
  t.date :expiration_date
  t.timestamps
end

add_index :food_trucks, :active
add_index :food_trucks, :facility_type
add_index :food_trucks, :food_items
add_index :food_trucks, :status
```

### Create Adventure Food Trucks
**File**: `db/migrate/20231021224249_create_adventure_food_trucks.rb`

```ruby
create_table :adventure_food_trucks do |t|
  t.references :adventure, null: false, foreign_key: true
  t.references :food_truck, null: false, foreign_key: true
  t.integer :order, null: false, default: 0
  t.timestamps
end
```

---

## Query Patterns

### Find Active Trucks by Category

```ruby
FoodTruck.active
         .where('categories && ARRAY[?]::text[]', 'Mexican Food')
```

**Explanation**: PostgreSQL array overlap operator `&&` checks if categories array contains the specified category.

### Find Adventure's Next Truck

```ruby
adventure.adventure_food_trucks
         .find_by(order: adventure.current_truck_index)
         &.food_truck
```

### Recent Adventure for Phone Number

```ruby
Adventure.order(created_at: :desc)
         .find_by(phone_number: normalized_phone)
```

### Adventures Awaiting Start

```ruby
Adventure.awaiting_start
         .where('adventure_day <= ?', Date.today)
```

### Incomplete Adventures (for cleanup)

```ruby
Adventure.where(status: [:awaiting_start, :in_progress])
         .where('updated_at < ?', 24.hours.ago)
```

---

## Database Performance Considerations

### Current Indexes
- Status-based queries well-indexed
- Foreign keys indexed automatically
- Geographic queries could benefit from spatial indexes (PostGIS)

### Potential Index Additions

```sql
-- Composite index for food preference + status queries
CREATE INDEX idx_adventures_on_food_preference_and_status
  ON adventures(food_preference, status);

-- GiST index for geographic queries (requires PostGIS)
CREATE EXTENSION postgis;
CREATE INDEX idx_food_trucks_location
  ON food_trucks USING GIST(ll_to_earth(latitude, longitude));

-- Index for categories array queries
CREATE INDEX idx_food_trucks_categories
  ON food_trucks USING GIN(categories);
```

### Query Optimization Tips

1. **N+1 Queries**: Always use `includes(:food_trucks)` when loading adventures with trucks
2. **Array Queries**: GIN indexes speed up array overlap operations
3. **Geocoding**: Cache geocoded zip codes to avoid repeated calculations
4. **Expired Trucks**: Add `AND active = true` to all FoodTruck queries

---

## Data Integrity

### Foreign Key Constraints
- Enforced at database level
- `ON DELETE` behavior: `CASCADE` (deleting adventure deletes associated adventure_food_trucks)

### Data Validation Layers
1. **Database**: NOT NULL constraints, foreign keys
2. **Model**: Rails validations (format, presence, numericality)
3. **Application**: Business logic (e.g., status transitions)

### Potential Issues

**Phone Number Privacy**:
- Deleted on adventure completion
- If system crashes mid-completion, phone may persist (add cleanup job)

**Stale Adventures**:
- No automatic cleanup (recommendation: implement AdventureCleanupWorker)

**Inactive Trucks in Adventures**:
- If truck marked inactive mid-adventure, adventure continues
- Consider adding validation or warning

---

## Backup & Restore

### Recommended Backup Strategy

```bash
# Daily automated backup
pg_dump -Fc food_production > backup_$(date +%Y%m%d).dump

# Restore
pg_restore -d food_production backup_20231225.dump
```

### Critical Data
1. **Adventures**: User-generated, not reproducible
2. **Food Trucks**: Reproducible from CSV import
3. **Adventure Food Trucks**: Critical for in-progress adventures

### Data Retention
- Consider archiving completed adventures older than 90 days
- Keep phone numbers deleted adventures for privacy
- Retain food truck historical data for analytics
