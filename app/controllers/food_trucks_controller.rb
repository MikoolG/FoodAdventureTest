# frozen_string_literal: true

class FoodTrucksController < ApplicationController
  def index
    @food_trucks = FoodTruck.all
    respond_to do |format|
      format.json { render json: @food_trucks }
    end
  end
end
