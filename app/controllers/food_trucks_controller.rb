# frozen_string_literal: true

class FoodTrucksController < ApplicationController
  def index
    @food_trucks = FoodTruck.all
  end
end
