# frozen_string_literal: true

class AdventureFoodTruckJob < ApplicationJob
  queue_as :default

  def perform(adventure_id)
    adventure = Adventure.find(adventure_id)

    organizer = FoodTruckOrganizer.new(adventure)
    organizer.organize
  end
end
