class CreateAdventureFoodTrucks < ActiveRecord::Migration[7.0]
  def change
    create_table :adventure_food_trucks do |t|
      t.references :adventure, null: false, foreign_key: true
      t.references :food_truck, null: false, foreign_key: true
      t.integer :order, null: false, default: 0

      t.timestamps
    end
  end
end
