# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 20_231_021_224_249) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'adventure_food_trucks', force: :cascade do |t|
    t.bigint 'adventure_id', null: false
    t.bigint 'food_truck_id', null: false
    t.integer 'order', default: 0, null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['adventure_id'], name: 'index_adventure_food_trucks_on_adventure_id'
    t.index ['food_truck_id'], name: 'index_adventure_food_trucks_on_food_truck_id'
  end

  create_table 'adventures', force: :cascade do |t|
    t.string 'phone_number'
    t.string 'food_preference'
    t.string 'city'
    t.string 'state'
    t.string 'zip_code'
    t.decimal 'latitude', precision: 9, scale: 6
    t.decimal 'longitude', precision: 9, scale: 6
    t.integer 'number_of_trucks'
    t.date 'adventure_day'
    t.time 'adventure_start_time'
    t.integer 'status', default: 0
    t.integer 'current_truck_index', default: 0
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['city'], name: 'index_adventures_on_city'
    t.index ['food_preference'], name: 'index_adventures_on_food_preference'
    t.index ['state'], name: 'index_adventures_on_state'
    t.index ['status'], name: 'index_adventures_on_status'
  end

  create_table 'food_trucks', force: :cascade do |t|
    t.string 'applicant'
    t.string 'facility_type'
    t.text 'location_description'
    t.string 'address'
    t.string 'status'
    t.text 'categories', default: [], array: true
    t.text 'food_items'
    t.decimal 'latitude', precision: 9, scale: 6
    t.decimal 'longitude', precision: 9, scale: 6
    t.string 'schedule'
    t.string 'days_hours'
    t.boolean 'active', default: true
    t.date 'expiration_date'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['active'], name: 'index_food_trucks_on_active'
    t.index ['facility_type'], name: 'index_food_trucks_on_facility_type'
    t.index ['food_items'], name: 'index_food_trucks_on_food_items'
    t.index ['status'], name: 'index_food_trucks_on_status'
  end

  add_foreign_key 'adventure_food_trucks', 'adventures'
  add_foreign_key 'adventure_food_trucks', 'food_trucks'
end
