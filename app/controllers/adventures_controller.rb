# frozen_string_literal: true

class AdventuresController < ApplicationController
  def index; end

  def new
    @adventure = Adventure.new
  end

  def create
    @adventure = Adventure.new(adventure_params)
    if @adventure.save
      redirect_to adventure_begins_adventures_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @adventure = Adventure.find(params[:id])
  end

  def adventure_begins; end

  private

  def adventure_params
    params.require(:adventure).permit(:phone_number, :city, :zip_code, :food_preference, :number_of_trucks, :adventure_day,
                                      :adventure_start_time)
  end
end
