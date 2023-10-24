# frozen_string_literal: true

class FoodTruckOrganizer
  def initialize(adventure)
    @adventure = adventure
  end

  def organize
    # Filter by food preference
    trucks = FoodTruck.where("categories && ARRAY[?]::text[]", @adventure.food_preference)
    # Sort by approximate distance
    sorted_trucks = trucks.sort_by do |truck|
      distance_from_adventure(truck, @adventure)
    end
    
    # Take the number of trucks the user requested
    selected_trucks = sorted_trucks.first(@adventure.number_of_trucks)

    # Save the selected trucks as AdventureFoodTruck records
    save_as_adventure_food_trucks(selected_trucks)
  end

  private

  def save_as_adventure_food_trucks(trucks)
    trucks.each_with_index do |truck, index|
      AdventureFoodTruck.create(
        adventure: @adventure,
        food_truck: truck,
        order: index # Starts ordering from 0
      )
    end
  end

  def distance_from_adventure(truck, adventure)
    user_coordinates = [adventure.latitude, adventure.longitude]
    truck_coordinates = [truck.latitude, truck.longitude]
    Geocoder::Calculations.distance_between(user_coordinates, truck_coordinates)
  end
end
