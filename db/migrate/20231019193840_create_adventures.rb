class CreateAdventures < ActiveRecord::Migration[7.0]
  def change
    create_table :adventures do |t|
      t.string :phone_number
      t.string :food_preference
      t.string :city
      t.string :state
      t.string :zip_code
      t.integer :number_of_trucks
      t.date :adventure_day
      t.time :adventure_start_time

      t.timestamps
    end
    
    add_index :adventures, :city
    add_index :adventures, :state
    add_index :adventures, :food_preference
  end
end
