# frozen_string_literal: true

class AdventuresController < ApplicationController
  def new
    @adventure = Adventure.new
  end

  def create
    @adventure = Adventure.new(adventure_params)
    if @adventure.save
      redirect_to @adventure
    else
      render :new
    end
  end

  def show
    @adventure = Adventure.find(params[:id])
  end

  private

  def adventure_params
    params.require(:adventure).permit(:phone_number, :food_preference, :number_of_trucks, :adventure_day,
                                      :adventure_start_time)
  end
end
