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

ActiveRecord::Schema[7.0].define(version: 2023_10_19_194409) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "adventures", force: :cascade do |t|
    t.string "phone_number"
    t.string "food_preference"
    t.integer "number_of_trucks"
    t.date "adventure_day"
    t.time "adventure_start_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "food_trucks", force: :cascade do |t|
    t.string "applicant"
    t.string "facility_type"
    t.text "location_description"
    t.string "address"
    t.string "status"
    t.text "food_items"
    t.float "latitude"
    t.float "longitude"
    t.string "schedule"
    t.string "days_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
