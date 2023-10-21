class CreateFoodTrucks < ActiveRecord::Migration[7.0]
  def change
    create_table :food_trucks do |t|
      t.string :applicant
      t.string :facility_type
      t.text :location_description
      t.string :address
      t.string :status
      t.text :food_items
      t.float :latitude
      t.float :longitude
      t.string :schedule
      t.string :days_hours
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :food_trucks, :facility_type
    add_index :food_trucks, :status
    add_index :food_trucks, :food_items
    add_index :food_trucks, :active
  end
end
