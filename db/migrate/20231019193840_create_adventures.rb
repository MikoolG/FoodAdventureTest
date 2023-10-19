class CreateAdventures < ActiveRecord::Migration[7.0]
  def change
    create_table :adventures do |t|
      t.string :phone_number
      t.string :food_preference
      t.integer :number_of_trucks
      t.date :adventure_day
      t.time :adventure_start_time

      t.timestamps
    end
  end
end
