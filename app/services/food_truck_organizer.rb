class FoodTruckOrganizer
    def initialize(adventure)
      @adventure = adventure
    end
  
    def organize
      # Filter by food preference
      trucks = FoodTruck.where(food_items: @adventure.food_preference)
      
      # Sort by approximate distance
      sorted_trucks = trucks.sort_by do |truck|
        distance_from_adventure(truck, @adventure)
      end
      
      # Take the number of trucks the user requested
      sorted_trucks.first(@adventure.number_of_trucks)
    end
  
    private
  
    def distance_from_adventure(truck, adventure)
        user_coordinates = [adventure.latitude, adventure.longitude]
        truck_coordinates = [truck.latitude, truck.longitude]
        Geocoder::Calculations.distance_between(user_coordinates, truck_coordinates)
    end
  end