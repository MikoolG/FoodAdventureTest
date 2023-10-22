# frozen_string_literal: true

class CreateAdventures < ActiveRecord::Migration[7.0]
  def change
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
    add_index :adventures, :state
    add_index :adventures, :food_preference
    add_index :adventures, :status
  end
end
